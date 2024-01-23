// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import {LocalTest} from "utils/LocalTest.sol";
import {MultiplexUtils} from "utils/MultiplexUtils.sol";
import {LibCommonRichErrors} from "src/errors/LibCommonRichErrors.sol";
import {LibOwnableRichErrors} from "src/errors/LibOwnableRichErrors.sol";
import {BatchMultiplexValidator} from "src/examples/BatchMultiplexValidator.sol";
import {LibSignature} from "src/features/libs/LibSignature.sol";
import {LibNativeOrder} from "src/features/libs/LibNativeOrder.sol";
import {IBatchMultiplexFeature} from "src/features/interfaces/IBatchMultiplexFeature.sol";
import {IMetaTransactionsFeatureV2} from "src/features/interfaces/IMetaTransactionsFeatureV2.sol";
import "src/transformers/LibERC20Transformer.sol";
import "src/IZeroEx.sol";

interface IMockBM {
    enum ErrorHandling {
        REVERT,
        STOP,
        CONTINUE,
        UNKNOWN
    }

    function batchMultiplexOptionalParams(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress,
        ErrorHandling errorType
    ) external payable returns (bytes[] memory results);
}

contract BatchMultiplex is LocalTest, MultiplexUtils {
    event RfqOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        bytes32 pool
    );

    event LimitOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address feeRecipient,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        uint128 takerTokenFeeFilledAmount,
        uint256 protocolFeePaid,
        bytes32 pool
    );

    address public immutable _validator;

    constructor() public {
        _validator = address(new BatchMultiplexValidator());
    }

    receive() external payable {}

    function _executeBatchMultiplexTransactions(bytes[] memory callData) private {
        zeroExDeployed.zeroEx.batchMultiplex(callData);
    }

    function _executeBatchMultiplexTransactions(bytes[] memory callData, uint256 amount) private {
        zeroExDeployed.zeroEx.batchMultiplex{value: amount}(callData);
    }

    // batch
    function test_multiplex_multiplexBatchSellTokenForToken_rfqOrder() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        _mintTo(address(rfqOrder.takerToken), rfqOrder.taker, rfqOrder.takerAmount);

        zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken(
            dai,
            zrx,
            _makeArray(_makeRfqSubcall(rfqOrder)),
            rfqOrder.takerAmount,
            rfqOrder.makerAmount
        );
    }

    function test_batchMultiplex_multiplexBatchSellTokenForToken_rfqOrder() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        _mintTo(address(rfqOrder.takerToken), rfqOrder.taker, rfqOrder.takerAmount);

        bytes memory callData = abi.encodeWithSelector(
            zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken.selector,
            dai,
            zrx,
            _makeArray(_makeRfqSubcall(rfqOrder)),
            rfqOrder.takerAmount,
            rfqOrder.makerAmount
        );

        // direct call to implementation is not allowed
        vm.expectRevert("Batch_M_Feat/DIRECT_CALL_ERROR");
        zeroExDeployed.features.batchMultiplexFeature.batchMultiplex(_makeArray(callData));

        _executeBatchMultiplexTransactions(_makeArray(callData));
    }

    function test_batchMultiplex_fillRfqOrder_revertsWithInternalMethod() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        _mintTo(address(rfqOrder.takerToken), rfqOrder.taker, rfqOrder.takerAmount);
        (, LibSignature.Signature memory sig) = _makeRfqSubcallForBatch(rfqOrder, rfqOrder.takerAmount);

        // test revert onlySelf when calling method directly
        vm.expectRevert(LibCommonRichErrors.OnlyCallableBySelfError(address(this)));
        zeroExDeployed.zeroEx._fillRfqOrder(rfqOrder, sig, rfqOrder.makerAmount, rfqOrder.taker, true, address(this));

        bytes[] memory callsArray = new bytes[](1);
        callsArray[0] = abi.encodeWithSelector(
            zeroExDeployed.zeroEx._fillRfqOrder.selector,
            rfqOrder,
            sig,
            rfqOrder.makerAmount,
            rfqOrder.taker,
            true,
            address(this)
        );

        vm.expectRevert(LibCommonRichErrors.OnlyCallableBySelfError(address(this)));
        _executeBatchMultiplexTransactions(callsArray);
    }

    function test_batchMultiplex_extend_revertsOnRoleTakeover() external {
        // should revert when trying to add a selector mapping
        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        zeroExDeployed.zeroEx.extend(bytes4(keccak256("_extendSelf(bytes4,address)")), address(1));

        // we try and get same result with batchMultiplex
        bytes[] memory callsArray = new bytes[](1);
        callsArray[0] = abi.encodeWithSelector(
            zeroExDeployed.zeroEx.extend.selector,
            bytes4(keccak256("_extendSelf(bytes4,address)")),
            address(1)
        );

        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        _executeBatchMultiplexTransactions(callsArray);

        // TODO: test the following assertiong with multiple calls
        bytes memory mockBytes = callsArray[0];
        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        zeroExDeployed.zeroEx.batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IBatchMultiplexFeature.ErrorHandling.REVERT
        );

        // does not extend but does stops instead of reverting
        zeroExDeployed.zeroEx.batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IBatchMultiplexFeature.ErrorHandling.STOP
        );

        // does not extend but tries to continue exeuting next txns
        zeroExDeployed.zeroEx.batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IBatchMultiplexFeature.ErrorHandling.CONTINUE
        );
    }

    function test_batchMultiplex_revertsWithUnknownRevertErrorType() external {
        bytes[] memory callsArray = new bytes[](1);
        callsArray[0] = abi.encodeWithSelector(
            zeroExDeployed.zeroEx.extend.selector,
            bytes4(keccak256("_extendSelf(bytes4,address)")),
            address(1)
        );
        bytes memory mockBytes = callsArray[0];

        bytes memory unknownRevertCalldata = abi.encodeWithSelector(
            IBatchMultiplexFeature.batchMultiplexOptionalParams.selector,
            callsArray,
            mockBytes,
            address(0),
            IMockBM.ErrorHandling.UNKNOWN
        );
        vm.expectRevert();
        (bool revertsAsExpected, ) = address(zeroExDeployed.zeroEx).call(unknownRevertCalldata);
        assertTrue(revertsAsExpected, "expectRevert: call did not revert");

        // TODO: not sure EVM returns the expected error when a different enum type is used, will not be
        //  able to reproduce error in coverage
        vm.expectRevert();
        IMockBM(address(zeroExDeployed.zeroEx)).batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IMockBM.ErrorHandling.UNKNOWN
        );

        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        IMockBM(address(zeroExDeployed.zeroEx)).batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IMockBM.ErrorHandling.REVERT
        );
    }

    function test_batchMutiplex_rfqOrderMultiplexFallbackUniswapV2() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        _createUniswapV2Pool(uniV2Factory, dai, zrx, 10e18, 10e18);
        _mintTo(address(rfqOrder.takerToken), rfqOrder.taker, 10 * rfqOrder.takerAmount);

        (bytes memory callData, ) = _makeRfqSubcallForBatch(rfqOrder, rfqOrder.takerAmount);
        //_mintTo(address(dai), otherSignerAddress, 2e18);

        bytes memory uniswapV2FallbackData = abi.encodeWithSelector(
            zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken.selector,
            dai,
            zrx,
            _makeArray(_makeUniswapV2BatchSubcall(_makeArray(address(dai), address(zrx)), 2 * 1e18, false)),
            1e18,
            0
        );

        vm.expectEmit(true, true, true, true);
        emit RfqOrderFilled(
            zeroExDeployed.features.nativeOrdersFeature.getRfqOrderHash(rfqOrder),
            rfqOrder.maker,
            rfqOrder.taker,
            address(rfqOrder.makerToken),
            address(rfqOrder.takerToken),
            rfqOrder.takerAmount,
            rfqOrder.makerAmount,
            rfqOrder.pool
        );

        _executeBatchMultiplexTransactions(_makeArray(callData, uniswapV2FallbackData));
    }

    function test_batchMutiplex_rfqOrderLimitOrderBatch() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        _mintTo(address(rfqOrder.takerToken), rfqOrder.taker, 10 * rfqOrder.takerAmount);
        LibNativeOrder.LimitOrder memory limitOrder = _makeTestLimitOrder();
        _mintTo(address(limitOrder.takerToken), limitOrder.taker, limitOrder.takerAmount);

        (bytes memory rfqCallData, ) = _makeRfqSubcallForBatch(rfqOrder, rfqOrder.takerAmount);
        (bytes memory limitCallData, ) = _makeLimitSubcallForBatch(limitOrder, limitOrder.takerAmount);

        vm.expectEmit(true, true, true, true);
        emit RfqOrderFilled(
            zeroExDeployed.features.nativeOrdersFeature.getRfqOrderHash(rfqOrder),
            rfqOrder.maker,
            rfqOrder.taker,
            address(rfqOrder.makerToken),
            address(rfqOrder.takerToken),
            rfqOrder.takerAmount,
            rfqOrder.makerAmount,
            rfqOrder.pool
        );

        vm.expectEmit(true, true, true, true);
        emit LimitOrderFilled(
            zeroExDeployed.features.nativeOrdersFeature.getLimitOrderHash(limitOrder),
            limitOrder.maker,
            limitOrder.taker,
            msg.sender,
            address(limitOrder.makerToken),
            address(limitOrder.takerToken),
            limitOrder.takerAmount,
            limitOrder.makerAmount,
            0,
            0,
            limitOrder.pool
        );

        _executeBatchMultiplexTransactions(_makeArray(rfqCallData, limitCallData));
    }

    function test_batchMutiplex_transformERC20() external {
        vm.deal(address(this), 1e19);
        ITransformERC20Feature.Transformation[] memory transformations = new ITransformERC20Feature.Transformation[](1);
        transformations[0].deploymentNonce = _findTransformerNonce(
            address(zeroExDeployed.transformers.wethTransformer),
            address(zeroExDeployed.transformerDeployer)
        );
        transformations[0].data = abi.encode(LibERC20Transformer.ETH_TOKEN_ADDRESS, 1e18);

        bytes memory callData = abi.encodeWithSelector(
            ITransformERC20Feature.transformERC20.selector,
            IERC20Token(LibERC20Transformer.ETH_TOKEN_ADDRESS),
            // output token
            IERC20Token(address(zeroExDeployed.weth)),
            // input token amount
            1e18,
            // min output token amount
            1e18,
            // list of transform
            transformations
        );

        _executeBatchMultiplexTransactions(_makeArray(callData), 1e18);
        assert(zeroExDeployed.weth.balanceOf(address(this)) == 1e18);
    }

    function test_batchMutiplex_FillLimitOrderPayable() external {
        LibNativeOrder.LimitOrder memory limitOrder = _makeTestLimitOrder();
        _mintTo(address(limitOrder.takerToken), limitOrder.taker, limitOrder.takerAmount);

        (bytes memory callData, ) = _makeLimitSubcallForBatch(limitOrder, limitOrder.takerAmount);

        //vm.deal(address(this), 1e19);

        // TODO: check why fails when sending value
        _executeBatchMultiplexTransactions(_makeArray(callData), 1e18);
        //_executeBatchMultiplexTransactions(_makeArray(callData));
    }
}
