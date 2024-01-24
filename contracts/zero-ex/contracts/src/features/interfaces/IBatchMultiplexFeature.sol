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

import "../../features/libs/LibTypes.sol";
import "../../storage/LibBatchMultiplexStorage.sol";

interface IBatchMultiplexFeature {
    struct UpdateSelectorStatus {
        // The selector of the function call.
        bytes4 selector;
        // The status of the selector.
        LibBatchMultiplexStorage.SelectorStatus status;
    }

    /// @dev Emitted whenever the owner updates the selectors' status.
    /// @param status Array of tuples of selectors and status (Whitelisted, Blacklisted, RequiresRouting).
    event SelectorStatusUpdated(UpdateSelectorStatus[] status);

    /// @dev Routes the swaps in the `data` array to the EP.
    /// @param data The array of swap transactions.
    /// @return results The array of returned values from the swap calls.
    function batchMultiplexCall(bytes[] calldata data) external payable returns (bytes[] memory results);

    /// @dev Routes the swaps in the `data` array to the EP after validating them in an external validator
    ///   contract and passes extra data and the desired error behavior.
    /// @param data The array of swap transactions.
    /// @param extraData A string of extra data for project-specific validation.
    /// @param validatorAddress The address of the validator contract.
    /// @param errorBehavior Number of the error behavior type when one of the swaps fails.
    /// @return results The array of returned values from the swap calls.
    function batchMultiplexOptionalParamsCall(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress,
        LibTypes.ErrorBehavior errorBehavior
    ) external payable returns (bytes[] memory results);

    /// @dev A method to update the batch multiplex storage slot. It is restricted to the EP owner.
    /// @param selectorsTuple Array of tuples of selector and selector status.
    function updateSelectorsStatus(UpdateSelectorStatus[] calldata selectorsTuple) external;

    /// @dev A public method to query whether a method is restricted.
    /// @notice Can be used by batchMultiplex for querying status of multiple selectors.
    function getSelectorStatus(bytes4) external view returns (LibBatchMultiplexStorage.SelectorStatus selectorStatus);
}
