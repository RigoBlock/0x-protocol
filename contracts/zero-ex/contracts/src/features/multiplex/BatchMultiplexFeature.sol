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

    /// @inheritdoc IFeature
    string public constant override FEATURE_NAME = "BatchMultiplexFeature";
    /// @inheritdoc IFeature
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

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

    constructor() public FixinCommon() {}

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.batchMultiplex.selector);
        _registerFeatureFunction(this.batchMultiplexOptionalParams.selector);
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
                _revertWithData(result);
            }

            results[i] = result;
        }
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
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

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
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    /// @notice as in ZeroEx.sol _revertWithData private method
    function _revertWithData(bytes memory data) private pure {
        assembly {
            revert(add(data, 32), mload(data))
        }
    }

    function _checkDelegateCall() private view {
        require(address(this) != _implementation, "Batch_M_Feat/DIRECT_CALL_ERROR");
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

    function _isContract(address target) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(target)
        }
        return size != 0;
    }
}
