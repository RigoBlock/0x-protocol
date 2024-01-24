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

import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinReentrancyGuard.sol";
import "../../migrations/LibMigrate.sol";
import "../interfaces/IBatchMultiplexV2Feature.sol";
import "../interfaces/IFeature.sol";

/// @dev This feature enables batch transactions by re-routing the single swaps to the exchange proxy.
contract BatchMultiplexV2Feature is IFeature, IBatchMultiplexV2Feature, FixinCommon, FixinReentrancyGuard {
    /// @inheritdoc IFeature
    string public constant override FEATURE_NAME = "BatchMultiplexV2Feature";
    /// @inheritdoc IFeature
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev Ensures that the ETH balance of `this` does not go below the
    ///      initial ETH balance before the call (excluding ETH attached to the call).
    modifier doesNotReduceEthBalance() {
        uint256 initialBalance = address(this).balance;
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
    function migrate() external onlyDelegateCall returns (bytes4 success) {
        _registerFeatureFunction(this.batchMultiplexV2.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @inheritdoc IBatchMultiplexV2Feature
    function batchMultiplexV2(
        bytes[] calldata data
    )
        external
        override
        onlyDelegateCall
        nonReentrant(REENTRANCY_BATCH_MULTIPLEX)
        doesNotReduceEthBalance
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

    /// @dev Revert with direct call to implementation.
    function _checkDelegateCall() private view {
        require(address(this) != _implementation, "Batch_M_Feat/DIRECT_CALL_ERROR");
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
