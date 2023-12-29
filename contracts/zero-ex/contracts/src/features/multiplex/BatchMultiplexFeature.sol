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

pragma solidity 0.8.19;

import "../../examples/BatchMultiplexValidator.sol";
import "../../fixins/FixinCommon.sol";
import "../../migrations/LibMigrate.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IBatchMultiplexFeature.sol";

/// @dev This feature enables batch transactions by re-routing the single swaps to the exchange proxy.
contract MultiplexFeature is
    IFeature,
    IBatchMultiplexFeature,
    FixinCommon
{
    // TODO: select only one `validate` method in validator contract
    //bytes4 private constant _validateSelector = BatchMultiplexValidator.validate.selector;
    bytes4 private constant _validateSelector = bytes4(keccak256("validate(bytes[],bytes,address)"));

    // TODO: remove as this is mock for validator setup
    address private immutable _validator;

    // TODO: check as visibility of immutables should be `external`
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "BatchMultiplexFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    error UnknownErrorHandling();

    // TODO: this address is stored as immutable in FixinCommon, however we may have to implement a new
    //   modifier to assert that only delegatecalls can be performed (if required check).
    //  remove mock validator and deploy in tests pipeline.
    constructor() FixinCommon() {
        _validator = address(new BatchMultiplexValidator());
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    // TODO: verify: 2 methods with same name require encoding, cannot be returned my method.selector.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(abi.encodeWithSignature("batchMultiplex("bytes[]")");
        _registerFeatureFunction(abi.encodeWithSignature("batchMultiplex("bytes[]","bytes","address")");
        // we may use the following method if we used a unified batchMultiplex method.
        //_registerFeatureFunction(this.batchMultiplex.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @inheritdoc IBatchMultiplexFeature
    /// TODO: it could be more gas efficient to modify visibility of method to `external` and implement
    ///   logic in an internal/private method which can be called by the other methods as well.
    /// TODO: the batchMultiplex methods should use a nonReentrant modifier, which could be made less
    ///   gas expensive by using transient storage after the Cancun hardfork (Q1 2024). However, a reentrancy
    ///   in this context would only be caused by the `data` to contain a batchMultiplex call. We could add
    ///   the check to prevent unintended behavior.
    function batchMultiplex(bytes[] calldata data) public returns (bytes[] memory results) {
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
    // could also be validated for every call, i.e. allow stop, revert or continue.
    function batchMultiplex(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress
    ) external returns (bytes[] memory results) {
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
    ) external returns (bytes[] memory results) {
        _validateCalldata(data, extraData, validatorAddress);

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
                    revert UnknownErrorHandling();
                }
            }

            results[i] = result;
        }
    }

    /// extraData should include encoded validator address as first arg, encoded error type enum as last byte, we could then decode
    /// these values and pass the chopped extradata to the validator (only chop validator address).
    /// @notice We perform a staticcall to prevent reentrancy or other sorts of attacks by external contract, i.e. no state changes.
    //    However, this could levied at a later stage. While the method is protected against internal state changes, nothing
    //    guarantees that the transaction is protected against frontrunning --> should not rely on this validation for
    //    onchain variables that can be manipulated, i.e. oracles or similar.
    /// @notice We could change visibility of this method to `public` so the call can be validated by client before
    ///   being sent to the network.
    function _validateCalldata(bytes[] calldata data, bytes calldata extraData, address validatorAddress) private view {
        //mock code, validator is arbitrary from caller with no impact as it is a staticcall
        assert(validatorAddress == validator());
        (bool success, bytes memory returndata) = address(validator()).staticcall(
            abi.encodeWithSelector(
                _getValidateSelector(),
                data,
                extraData,
                msg.sender
            )
        );

        // we assert that data is returned by the validator contract and that it is indeed a contract. If we moved
        //  revertbehavior to validator contract, we could return the error type here, but it could mean higher gas cost.
        assert(success && abi.decode(returndata, (bool)) && address(validator()).code.length > 0);
    }

    /// TODO: remove this method as the validator in an arbitrary address input of the client that requires extra validation.
    function validator() public view returns (address) {
        return _validator;
    }

    function _getValidateSelector() private pure returns (bytes4) { return _validateSelector; }
}
