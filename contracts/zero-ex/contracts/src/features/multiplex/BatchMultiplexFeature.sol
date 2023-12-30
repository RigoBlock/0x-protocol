// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2024 ZeroEx Intl., RigoBlock Intl.
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

// This contract uses libraries that are compiled with an earlier version of solidity. We should check
//  if can upgrade those libraries to use a more recent version.
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "../../examples/BatchMultiplexValidator.sol";
import "../../fixins/FixinCommon.sol";
import "../../migrations/LibMigrate.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IBatchMultiplexFeature.sol";

/// @dev This feature enables batch transactions by re-routing the single swaps to the exchange proxy.
contract BatchMultiplexFeature is IFeature, IBatchMultiplexFeature, FixinCommon {
    bytes4 private constant _VALIDATE_SELECTOR = BatchMultiplexValidator.validate.selector;

    // TODO: remove as this is mock for validator setup and tests
    address public immutable _validator;

    // TODO: check as visibility of immutables should be `external`
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "BatchMultiplexFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    // TODO: this address is stored as immutable in FixinCommon, however we may have to implement a new
    //   modifier to assert that only delegatecalls can be performed (if required check).
    constructor() public FixinCommon() {
        // TODO: remove mock validator and deploy in tests pipeline.
        _validator = address(new BatchMultiplexValidator());
    }

    // TODO: could define a _registerFeatureFunction internal virtual override method
    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    // TODO: verify: 2 methods with same name require encoding, cannot be returned my method.selector.
    function migrate() external returns (bytes4 success) {
        // we may use the following method if we used a unified batchMultiplex method.
        //_registerFeatureFunction(this.batchMultiplex.selector);
        _registerFeatureFunction(bytes4(keccak256("batchMultiplex(bytes[])")));
        _registerFeatureFunction(bytes4(keccak256("batchMultiplex(bytes[],bytes,address)")));
        _registerFeatureFunction(bytes4(keccak256("batchMultiplex(bytes[],bytes,address,uint256)")));
        return LibMigrate.MIGRATE_SUCCESS;
    }

    // TODO: all methods could potentially be merged and params made optional by api. This will add a marginal
    //  cost to the swap transaction (≃60 extra gas in total) but expose only two batchMultiplex method.
    //  Also check if should assert inputs validity.
    /// @inheritdoc IBatchMultiplexFeature
    // could also be validated for every call, i.e. allow stop, revert or continue.
    function batchMultiplex(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress
    ) external override returns (bytes[] memory results) {
        _validateCalldata(data, extraData, validatorAddress);
        results = batchMultiplex(data);
    }

    /// @inheritdoc IBatchMultiplexFeature
    /// @notice This method should be used to get desired behavior STOP, REVERT, CONTINUE
    function batchMultiplex(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress,
        ErrorHandling errorType
    ) external override returns (bytes[] memory results) {
        // TODO: can alternatively expose a fourth "batchMultiplex(bytes[], ErrorHandling)" method.
        // skip validation if validator is nil address, allows sending a batch of swaps with desired error behavior
        //  by using nil address as validator.
        if (validatorAddress != address(0)) {
            _validateCalldata(data, extraData, validatorAddress);
        }

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                if (errorType == ErrorHandling.REVERT) {
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

    // TODO: the batchMultiplex methods should use a nonReentrant modifier, which could be made less
    //  gas expensive by using transient storage after the Cancun hardfork (Q1 2024). However, a reentrancy
    //  in this context would only be caused by the `data` to contain a batchMultiplex call. We could add
    //  the check to prevent unintended behavior. Underlying methods use their reentrancy modifier.
    /// @inheritdoc IBatchMultiplexFeature
    function batchMultiplex(bytes[] calldata data) public override returns (bytes[] memory results) {
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

    // TODO: check if this validation is useful at all as the validation address is arbitrary. Technically, the same
    //  transactions could be sent 1) to a validator that always returns `true` or 2) with a different batchMultiplex
    //  or 3) even via single transactions. The sender of this message should be a contract, and the transaction should
    //  be re-routed to the msg.sender as a callback.
    /// extraData should include encoded validator address as first arg, encoded error type enum as last byte, we could
    ///  then decode these values and pass the chopped extradata to the validator (only chop validator address).
    /// @notice We perform a staticcall to prevent reentrancy or other sorts of attacks by external contract, i.e. no
    //    state changes. However, this could levied at a later stage. While the method is protected against internal
    //    state changes, nothing guarantees that the transaction is protected against frontrunning --> should not rely
    //    on this validation for onchain variables that can be manipulated, i.e. oracles or similar.
    /// @notice We could change visibility of this method to `public` so the call can be validated by client before
    ///   being sent to the network.
    function _validateCalldata(bytes[] calldata data, bytes calldata extraData, address validatorAddress) private view {
        //mock code, validator is arbitrary from caller with no impact as it is a staticcall
        (bool success, bytes memory returndata) = validatorAddress.staticcall(
            abi.encodeWithSelector(_getValidateSelector(), data, extraData, msg.sender)
        );

        // we assert that data is returned by the validator contract and that it is a contract. If we moved revert
        //  behavior to validator contract, we could return the error type here, but it could mean higher gas cost.
        //  Reverts if target validator does not implement `validate` method.
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
