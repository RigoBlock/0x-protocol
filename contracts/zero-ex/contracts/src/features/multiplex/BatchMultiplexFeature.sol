// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2024 ZeroEx Intl., Rigo Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IEtherToken.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../examples/BatchMultiplexValidator.sol";
import "../../features/libs/LibNativeOrder.sol";
import "../../features/libs/LibNFTOrder.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinReentrancyGuard.sol";
import "../../migrations/LibMigrate.sol";
import "../../storage/LibBatchMultiplexStorage.sol";
import "../../storage/LibProxyStorage.sol";
import "../../transformers/LibERC20Transformer.sol";
import "../../vendor/ILiquidityProvider.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IBatchFillNativeOrdersFeature.sol";
import "../interfaces/IBatchMultiplexFeature.sol";
import "../interfaces/IERC721OrdersFeature.sol";
import "../interfaces/IERC1155OrdersFeature.sol";
import "../interfaces/ILiquidityProviderFeature.sol";
import "../interfaces/IMetaTransactionsFeature.sol";
import "../interfaces/IMetaTransactionsFeatureV2.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/INativeOrdersFeature.sol";
import "../interfaces/IPancakeSwapFeature.sol";
import "../interfaces/IOtcOrdersFeature.sol";
import "../interfaces/ITransformERC20Feature.sol";
import "../interfaces/IUniswapFeature.sol";
import "../interfaces/IUniswapV3Feature.sol";

/// @dev This feature enables batch transactions by re-routing the single swaps to the exchange proxy.
contract BatchMultiplexFeature is IFeature, IBatchMultiplexFeature, FixinCommon, FixinReentrancyGuard {
    bytes4 private constant _VALIDATE_SELECTOR = BatchMultiplexValidator.validate.selector;

    /// @inheritdoc IFeature
    string public constant override FEATURE_NAME = "BatchMultiplexFeature";
    /// @inheritdoc IFeature
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev The wrapped Ether token contract.
    IEtherToken private immutable WETH;

    /// @dev Refunds up to `msg.value` leftover ETH at the end of the call.
    modifier refundsAttachedEth() {
        uint256 initialBalance = address(this).balance - msg.value;
        _;
        // `doesNotReduceEthBalance` ensures address(this).balance >= initialBalance
        uint256 remainingBalance = LibSafeMathV06.min256(msg.value, address(this).balance - initialBalance);
        if (remainingBalance > 0) {
            msg.sender.transfer(remainingBalance);
        }
    }

    /// @dev Ensures that the ETH balance of `this` does not go below the
    ///      initial ETH balance before the call (excluding ETH attached to the call).
    modifier doesNotReduceEthBalance() {
        uint256 initialBalance = address(this).balance - msg.value;
        _;
        require(initialBalance <= address(this).balance, "Batch_M_Feat/ETH_LEAK");
    }

    // reading immutable through internal method more gas efficient
    modifier onlyDelegateCall() {
        _checkDelegateCall();
        _;
    }

    constructor(IEtherToken weth) public FixinCommon() {
        WETH = weth;
    }

    // TODO: this method can be called by anyone in the implementation, check if should be delegatecall restricted.
    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external onlyDelegateCall returns (bytes4 success) {
        _registerFeatureFunction(this.batchMultiplex.selector);
        _registerFeatureFunction(this.batchMultiplexOptionalParams.selector);
        _registerFeatureFunction(this.updateSelectorsStatus.selector);
        _registerFeatureFunction(this.getSelectorStatus.selector);

        // Initialize storage with restricted methods.
        _registerCustomMethods();
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @inheritdoc IBatchMultiplexFeature
    function batchMultiplex(
        bytes[] calldata data
    )
        external
        payable
        override
        onlyDelegateCall
        nonReentrant(REENTRANCY_BATCH_MULTIPLEX)
        doesNotReduceEthBalance
        refundsAttachedEth
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = _dispatch(data[i]);

            if (!success) {
                _revertWithData(result);
            }

            results[i] = result;
        }

        // TODO: use try/catch and return here
        // unwrap any WETH leftover
        _unwrapWethLeftover();
    }

    /// @inheritdoc IBatchMultiplexFeature
    /// @notice This method should be used to get desired behavior STOP, REVERT, CONTINUE.
    ///   Validator contract will optionally assert validity of `extraData`.
    function batchMultiplexOptionalParams(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress,
        ErrorHandling errorType
    )
        external
        payable
        override
        onlyDelegateCall
        nonReentrant(REENTRANCY_BATCH_MULTIPLEX)
        doesNotReduceEthBalance
        refundsAttachedEth
        returns (bytes[] memory results)
    {
        // skip validation if validator is nil address, allows sending a batch of swaps with desired error behavior
        //  by using nil address as validator.
        if (validatorAddress != address(0)) {
            _validateCalldata(data, extraData, validatorAddress);
        }

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = _dispatch(data[i]);

            if (!success) {
                if (errorType == ErrorHandling.REVERT) {
                    _revertWithData(result);
                } else if (errorType == ErrorHandling.STOP) {
                    break;
                } else if (errorType == ErrorHandling.CONTINUE) {
                    continue;
                } else {
                    revert("Batch_M_Feat/UNKNOW_ERROR");
                }
            }

            results[i] = result;
        }

        // unwrap any WETH leftover
        _unwrapWethLeftover();
    }

    /// @inheritdoc IBatchMultiplexFeature
    function updateSelectorsStatus(UpdateSelectorStatus[] memory selectorsTuple) external override onlyOwner {
        for (uint i = 0; i < selectorsTuple.length; i++) {
            LibBatchMultiplexStorage.Storage storage stor = LibBatchMultiplexStorage.getStorage();

            // revert to initial state if a methods is allowed. This means an upgrade that requires explicit
            //  method whitelisting will be able to selector will return status `Whitelisted`.
            if (selectorsTuple[i].status == LibBatchMultiplexStorage.SelectorStatus.Whitelisted) {
                delete stor.statusBySelectors[selectorsTuple[i].selector];
            } else {
                stor.statusBySelectors[selectorsTuple[i].selector] = selectorsTuple[i].status;
            }
        }

        emit SelectorStatusUpdated(selectorsTuple);
    }

    /// @dev A virtual method to retrieve method selector for routing to implementation.
    function _buyERC721(LibNFTOrder.ERC721Order memory, LibSignature.Signature memory, bytes memory) public {}

    /// @dev A virtual method to retrieve method selector for routing to implementation.
    function _buyERC1155(LibNFTOrder.ERC721Order memory, LibSignature.Signature memory, BuyParams memory) public {}

    /// @inheritdoc IBatchMultiplexFeature
    function getSelectorStatus(
        bytes4 selector
    ) external view override returns (LibBatchMultiplexStorage.SelectorStatus selectorStatus) {
        return LibBatchMultiplexStorage.getStorage().statusBySelectors[selector];
    }

    function _dispatch(bytes memory data) private returns (bool, bytes memory) {
        bytes4 selector = data.readBytes4(0);
        (LibBatchMultiplexStorage.Storage storage stor, LibProxyStorage.Storage storage proxyStor) = _getStorages();

        if (stor.statusBySelectors[selector] == LibBatchMultiplexStorage.SelectorStatus.Blacklisted) {
            revert("Batch_M_Feat/BLACKLISTED");
        } else if (stor.statusBySelectors[selector] == LibBatchMultiplexStorage.SelectorStatus.RequiresRouting) {
            if (selector == ITransformERC20Feature.transformERC20.selector) {
                return _executeTransformERC20Call(data);
            } else if (selector == ILiquidityProviderFeature.sellToLiquidityProvider.selector) {
                return _executeLiquidityProviderCall(data);
            } else if (selector == IERC721OrdersFeature.buyERC721.selector) {
                return _executeERC721BuyCall(data, proxyStor.impls[selector]);
            } else if (selector == IERC1155OrdersFeature.buyERC1155.selector) {
                return _executeERC1155BuyCall(data, proxyStor.impls[selector]);
            } else if (selector == INativeOrdersFeature.fillLimitOrder.selector) {
                // a custom handling is encoded as EP will try to refund msg.value - ethProtocolFeePaid
                return _executeFillLimitOrderCall(data);
            } else {
                revert("Batch_M_Feat/NOT_SUPPORTED");
            }
        } else {
            return address(this).delegatecall(data);
        }
    }

    /// @dev Execute a `ILiquidityProviderFeature.sellToLiquidityProvider()` call
    ///      by decoding the call args and translating the call to the external
    ///      `ILiquidityProviderFeature.sellToLiquidityProvider()` variant, with msg.sender
    ///      as the recipient and can attach Eth value to the call.
    function _executeERC721BuyCall(
        bytes memory callData,
        address featureImplementation
    ) private returns (bool, bytes memory) {
        (
            LibNFTOrder.ERC721Order memory sellOrder,
            LibSignature.Signature memory signature,
            bytes memory callbackData
        ) = abi.decode(callData, (LibNFTOrder.ERC721Order, LibSignature.Signature, bytes));
        return
            address(featureImplementation).delegatecall(
                abi.encodeWithSelector(
                    this._buyERC721.selector,
                    sellOrder,
                    signature,
                    address(this).balance,
                    callbackData
                )
            );
    }

    struct BuyParams {
        uint128 buyAmount;
        uint256 ethAvailable;
        bytes takerCallbackData;
    }

    /// @dev Execute a `ILiquidityProviderFeature.sellToLiquidityProvider()` call
    ///      by decoding the call args and translating the call to the external
    ///      `ILiquidityProviderFeature.sellToLiquidityProvider()` variant, with msg.sender
    ///      as the recipient and can attach Eth value to the call.
    function _executeERC1155BuyCall(
        bytes memory callData,
        address featureImplementation
    ) private returns (bool, bytes memory) {
        (
            LibNFTOrder.ERC1155Order memory sellOrder,
            LibSignature.Signature memory signature,
            uint128 erc1155BuyAmount,
            bytes memory callbackData
        ) = abi.decode(callData, (LibNFTOrder.ERC1155Order, LibSignature.Signature, uint128, bytes));
        return
            address(featureImplementation).delegatecall(
                abi.encodeWithSelector(
                    this._buyERC1155.selector,
                    sellOrder,
                    signature,
                    BuyParams(erc1155BuyAmount, address(this).balance, callbackData)
                )
            );
    }

    /// @dev Execute a `INativeOrdersFeature.fillLimitOrder()` meta-transaction call
    ///      by decoding the call args and translating the call to the internal
    ///      `INativeOrdersFeature._fillLimitOrder()` variant, where we can override
    ///      the taker address.
    function _executeFillLimitOrderCall(bytes memory callData) private returns (bool, bytes memory) {
        bytes memory args = _extractArgumentsFromCallData(callData);
        (
            LibNativeOrder.LimitOrder memory order,
            LibSignature.Signature memory signature,
            uint128 takerTokenFillAmount
        ) = abi.decode(args, (LibNativeOrder.LimitOrder, LibSignature.Signature, uint128));

        // We call with null value to prevent protocol fee refund revert with delegatecall. If the fee
        //  multiplier is positive, uint256(PROTOCOL_FEE_MULTIPLIER) * tx.gasprice will have to be sent.
        return
            address(this).call{value: 0}(
                abi.encodeWithSelector(
                    INativeOrdersFeature._fillLimitOrder.selector,
                    order,
                    signature,
                    takerTokenFillAmount,
                    msg.sender,
                    msg.sender
                )
            );
    }

    /// @dev Execute a `ILiquidityProviderFeature.sellToLiquidityProvider()` call
    ///      by decoding the call args and translating the call to the external
    ///      `ILiquidityProviderFeature.sellToLiquidityProvider()` variant, with msg.sender
    ///      as the recipient and can attach Eth value to the call.
    function _executeLiquidityProviderCall(bytes memory callData) private returns (bool, bytes memory) {
        bytes memory args = _extractArgumentsFromCallData(callData);

        (
            IERC20Token inputToken,
            IERC20Token outputToken,
            ILiquidityProvider provider,
            address recipient,
            uint256 sellAmount,
            uint256 minBuyAmount,
            bytes memory auxiliaryData
        ) = abi.decode(args, (IERC20Token, IERC20Token, ILiquidityProvider, address, uint256, uint256, bytes));

        // Delegatecall to self if ERC20 to ERC20/ETH swap, call `ITransformERC20Feature._transformERC20()`
        //  (internal variant) with value otherwise.
        if (!LibERC20Transformer.isTokenETH(inputToken)) {
            return address(this).delegatecall(callData);
        } else {
            return
                address(this).call{value: sellAmount}(
                    abi.encodeWithSelector(
                        ILiquidityProviderFeature.sellToLiquidityProvider.selector,
                        inputToken,
                        outputToken,
                        provider,
                        recipient,
                        sellAmount,
                        minBuyAmount,
                        auxiliaryData
                    )
                );
        }
    }

    /// @dev Arguments for a `TransformERC20.transformERC20()` call.
    struct ExternalTransformERC20Args {
        IERC20Token inputToken;
        IERC20Token outputToken;
        uint256 inputTokenAmount;
        uint256 minOutputTokenAmount;
        ITransformERC20Feature.Transformation[] transformations;
    }

    /// @dev Execute a `ITransformERC20Feature.transformERC20()` meta-transaction call
    ///      by decoding the call args and translating the call to the internal
    ///      `ITransformERC20Feature._transformERC20()` variant, where we can override
    ///      the taker address.
    function _executeTransformERC20Call(bytes memory callData) private returns (bool, bytes memory) {
        // HACK(dorothy-zbornak): `abi.decode()` with the individual args
        // will cause a stack overflow. But we can prefix the call data with an
        // offset to transform it into the encoding for the equivalent single struct arg,
        // since decoding a single struct arg consumes far less stack space than
        // decoding multiple struct args.

        // Where the encoding for multiple args (with the selector ommitted)
        // would typically look like:
        // | argument                 |  offset |
        // |--------------------------|---------|
        // | inputToken               |       0 |
        // | outputToken              |      32 |
        // | inputTokenAmount         |      64 |
        // | minOutputTokenAmount     |      96 |
        // | transformations (offset) |     128 | = 32
        // | transformations (data)   |     160 |

        // We will ABI-decode a single struct arg copy with the layout:
        // | argument                 |  offset |
        // |--------------------------|---------|
        // | (arg 1 offset)           |       0 | = 32
        // | inputToken               |      32 |
        // | outputToken              |      64 |
        // | inputTokenAmount         |      96 |
        // | minOutputTokenAmount     |     128 |
        // | transformations (offset) |     160 | = 32
        // | transformations (data)   |     192 |

        ExternalTransformERC20Args memory args;
        {
            bytes memory encodedStructArgs = new bytes(callData.length - 4 + 32);
            // Copy the args data from the original, after the new struct offset prefix.
            //bytes memory fromCallData = callData;
            assert(callData.length >= 160);
            uint256 fromMem;
            uint256 toMem;
            assembly {
                // Prefix the calldata with a struct offset,
                // which points to just one word over.
                mstore(add(encodedStructArgs, 32), 32)
                // Copy everything after the selector.
                fromMem := add(callData, 36)
                // Start copying after the struct offset.
                toMem := add(encodedStructArgs, 64)
            }
            LibBytesV06.memCopy(toMem, fromMem, callData.length - 4);
            // Decode call args for `ITransformERC20Feature.transformERC20()` as a struct.
            args = abi.decode(encodedStructArgs, (ExternalTransformERC20Args));
        }
        // Delegatecall to self if ERC20 to ERC20/ETH swap, call `ITransformERC20Feature._transformERC20()`
        //  (internal variant) with value otherwise.
        if (!LibERC20Transformer.isTokenETH(args.inputToken)) {
            return address(this).delegatecall(callData);
        } else {
            return
                address(this).call{value: args.inputTokenAmount}(
                    abi.encodeWithSelector(
                        ITransformERC20Feature._transformERC20.selector,
                        ITransformERC20Feature.TransformERC20Args({
                            taker: msg.sender,
                            inputToken: args.inputToken,
                            outputToken: args.outputToken,
                            inputTokenAmount: args.inputTokenAmount,
                            minOutputTokenAmount: args.minOutputTokenAmount,
                            transformations: args.transformations,
                            useSelfBalance: false,
                            recipient: msg.sender
                        })
                    )
                );
        }
    }

    /// @dev Extract arguments from call data by copying everything after the
    ///      4-byte selector into a new byte array.
    /// @param callData The call data from which arguments are to be extracted.
    /// @return args The extracted arguments as a byte array.
    function _extractArgumentsFromCallData(bytes memory callData) private pure returns (bytes memory args) {
        args = new bytes(callData.length - 4);
        uint256 fromMem;
        uint256 toMem;

        assembly {
            fromMem := add(callData, 36) // skip length and 4-byte selector
            toMem := add(args, 32) // write after length prefix
        }

        LibBytesV06.memCopy(toMem, fromMem, args.length);

        return args;
    }

    /// @dev Registers the non-supported methods or those that require re-routing.
    /// @notice When feature is upgraded, the EP storage is preserved. External method `updateSelectorsStatus` allows
    ///   the owner to change status of previously registered methods. This method should include all payable methods
    ///   and previously registered methods (unless storage slot cleared).
    function _registerCustomMethods() private {
        LibBatchMultiplexStorage.Storage storage stor = LibBatchMultiplexStorage.getStorage();

        // Meta transactions not supported.
        stor.statusBySelectors[IMetaTransactionsFeatureV2.executeMetaTransactionV2.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .Blacklisted;
        stor.statusBySelectors[
            IMetaTransactionsFeatureV2.batchExecuteMetaTransactionsV2.selector
        ] = LibBatchMultiplexStorage.SelectorStatus.Blacklisted;
        // meta transactions (v1) methods are payable and will require handling if supported in the future.
        // TODO: uncomment executeMetaTransaction after tests update
        //stor.statusBySelectors[
        //    IMetaTransactionsFeature.executeMetaTransaction.selector
        //] = LibBatchMultiplexStorage.SelectorStatus.Blacklisted;
        stor.statusBySelectors[
            IMetaTransactionsFeature.batchExecuteMetaTransactions.selector
        ] = LibBatchMultiplexStorage.SelectorStatus.Blacklisted;

        // Batch of NFT buys not supported but can be executed by combining them in an array of buys.
        stor.statusBySelectors[IERC721OrdersFeature.batchBuyERC721s.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .Blacklisted;
        stor.statusBySelectors[IERC1155OrdersFeature.batchBuyERC1155s.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .Blacklisted;

        // The following methods are not supported, but ERC20 to ERC20 can be executed in multiplex.
        stor.statusBySelectors[IOtcOrdersFeature.fillOtcOrderWithEth.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .Blacklisted;
        stor.statusBySelectors[IUniswapV3Feature.sellEthForTokenToUniswapV3.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .Blacklisted;
        stor.statusBySelectors[IPancakeSwapFeature.sellToPancakeSwap.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .Blacklisted;
        stor.statusBySelectors[IUniswapFeature.sellToUniswap.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .Blacklisted;

        // The following methods will revert whenever ETH is attached to the call and another subcall using
        //  ETH is appended to the subcalls array.
        stor.statusBySelectors[INativeOrdersFeature.fillOrKillLimitOrder.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .Blacklisted;
        stor.statusBySelectors[IBatchFillNativeOrdersFeature.batchFillLimitOrders.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .Blacklisted;

        // Multiplex payable methods not supported.
        stor.statusBySelectors[IMultiplexFeature.multiplexBatchSellEthForToken.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .RequiresRouting;
        stor.statusBySelectors[IMultiplexFeature.multiplexMultiHopSellEthForToken.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .RequiresRouting;

        // register methods that require special handling. Will revert with error if not implemented in explicit route.
        stor.statusBySelectors[ILiquidityProviderFeature.sellToLiquidityProvider.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .RequiresRouting;
        stor.statusBySelectors[ITransformERC20Feature.transformERC20.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .RequiresRouting;
        stor.statusBySelectors[IERC721OrdersFeature.buyERC721.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .RequiresRouting;
        stor.statusBySelectors[IERC1155OrdersFeature.buyERC1155.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .RequiresRouting;
        stor.statusBySelectors[INativeOrdersFeature.fillLimitOrder.selector] = LibBatchMultiplexStorage
            .SelectorStatus
            .RequiresRouting;
    }

    function _unwrapWethLeftover() private {
        try WETH.withdraw(WETH.balanceOf(address(this))) {
            return;
        } catch {}
    }

    /// @dev Revert with direct call to implementation.
    function _checkDelegateCall() private view {
        require(address(this) != _implementation, "Batch_M_Feat/DIRECT_CALL_ERROR");
    }

    /// @dev Revert when target address is EOA.
    function _isContract(address target) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(target)
        }
        return size != 0;
    }

    /// @dev An internal validator method. Reverts if validation in the validator contract fails.
    /// @notice Used by clients that want to assert extra-conditions with their own validation logic,
    ///   ensuring their interface processes transactions according to it.
    /// @param data The batch of 0x protocol transactions.
    /// @param extraData An arbitrary array of data to be validated.
    /// @param validatorAddress The address of the designated validator contract.
    function _validateCalldata(bytes[] calldata data, bytes calldata extraData, address validatorAddress) private view {
        // low-level call of BatchMultiplexValidator(validatorAddress).validate(abi.encode(data), extraData, msg.sender)
        (bool success, bytes memory returndata) = validatorAddress.staticcall(
            abi.encodeWithSelector(_getValidateSelector(), abi.encode(data), extraData, msg.sender)
        );

        // we assert that a boolean is returned by the validator contract and that it is a contract. Reverts if
        //  validator does not implement `validate` method.
        assert(success && abi.decode(returndata, (bool)) && _isContract(validatorAddress));
    }

    function _getValidateSelector() private pure returns (bytes4) {
        return _VALIDATE_SELECTOR;
    }

    /// @dev Get the storage buckets for this feature and the proxy.
    /// @return stor Storage bucket for this feature.
    /// @return proxyStor age bucket for the proxy.
    function _getStorages()
        private
        pure
        returns (LibBatchMultiplexStorage.Storage storage stor, LibProxyStorage.Storage storage proxyStor)
    {
        return (LibBatchMultiplexStorage.getStorage(), LibProxyStorage.getStorage());
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    /// @notice as in ZeroEx.sol _revertWithData private method
    function _revertWithData(bytes memory data) private pure {
        assembly {
            revert(add(data, 32), mload(data))
        }
    }
}
