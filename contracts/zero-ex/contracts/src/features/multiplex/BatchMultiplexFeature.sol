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

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../examples/BatchMultiplexValidator.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinReentrancyGuard.sol";
import "../../migrations/LibMigrate.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IBatchMultiplexFeature.sol";

/// @dev This feature enables batch transactions by re-routing the single swaps to the exchange proxy.
contract BatchMultiplexFeature is IFeature, IBatchMultiplexFeature, FixinCommon, FixinReentrancyGuard {
    bytes4 private constant _VALIDATE_SELECTOR = BatchMultiplexValidator.validate.selector;

    // TODO: remove as this is mock for validator setup and tests
    address public immutable _validator;

    /// @inheritdoc IFeature
    string public constant override FEATURE_NAME = "BatchMultiplexFeature";
    /// @inheritdoc IFeature
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev Refunds up to `msg.value` leftover ETH at the end of the call.
    modifier refundsAttachedEth() {
        _;
        uint256 remainingBalance = LibSafeMathV06.min256(msg.value, address(this).balance);
        if (remainingBalance > 0) {
            msg.sender.transfer(remainingBalance);
        }
    }

    /// @dev Ensures that the ETH balance of `this` does not go below the
    ///      initial ETH balance before the call (excluding ETH attached to the call).
    modifier doesNotReduceEthBalance() {
        uint256 initialBalance = address(this).balance - msg.value;
        _;
        require(initialBalance <= address(this).balance, "Batch_M_Feature/ETH_LEAK");
    }

    // reading immutable through internal method more gas efficient
    modifier onlyDelegateCall() {
        _checkDelegateCall();
        _;
    }

    constructor() public FixinCommon() {
        // TODO: remove mock validator and deploy in tests pipeline.
        _validator = address(new BatchMultiplexValidator());
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(bytes4(keccak256("batchMultiplex(bytes[])")));
        _registerFeatureFunction(bytes4(keccak256("batchMultiplex(bytes[],bytes,address)")));
        _registerFeatureFunction(bytes4(keccak256("batchMultiplex(bytes[],bytes,address,uint256)")));
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
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }

    /// @inheritdoc IBatchMultiplexFeature
    /// @notice Validator contract will assert validity of `extraData`.
    function batchMultiplex(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress
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
        results = batchMultiplex(data, extraData, validatorAddress, ErrorHandling.REVERT);
    }

    /// @inheritdoc IBatchMultiplexFeature
    /// @notice This method should be used to get desired behavior STOP, REVERT, CONTINUE.
    ///   Validator contract will assert validity of `extraData`.
    function batchMultiplex(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress,
        ErrorHandling errorType
    )
        public
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
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                if (errorType == ErrorHandling.REVERT) {
                    // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                    if (result.length < 68) revert();
                    assembly {
                        result := add(result, 0x04)
                    }
                    revert(abi.decode(result, (string)));
                } else if (errorType == ErrorHandling.STOP) {
                    break;
                } else if (errorType == ErrorHandling.CONTINUE) {
                    continue;
                } else {
                    // TODO: check if should add error from lib or upgrade to 0.8
                    revert("BATCH_MULTIPLEX_UNKNOW_ERROR");
                }
            }

            results[i] = result;
        }
    }

    function _checkDelegateCall() private view {
        require(address(this) != _implementation, "BATCH_M_DIRECT_CALL_ERROR");
    }

    /// @dev An internal validator method. Reverts if validation in the validator contract fails.
    /// @notice We perform a staticcall to prevent reentrancy or other sorts of attacks by external contract, i.e. no
    ///   state changes. However, this could be levied at a later stage. While the method is protected against internal
    ///   state changes, nothing guarantees that the transaction is protected against frontrunning --> should not rely
    ///   on this validation for onchain variables that can be manipulated, i.e. oracles or similar.
    ///   This validation is used by clients that want to assert extra-conditions with their own validation logic,
    ///   ensuring their interface processes transactions according to it. An example would be a backend EIP712-validate
    ///   a batch, then return the signature to the client as extraData and use the verifier to assert validity.
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

    function _isContract(address target) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(target)
        }
        return size != 0;
    }
}
