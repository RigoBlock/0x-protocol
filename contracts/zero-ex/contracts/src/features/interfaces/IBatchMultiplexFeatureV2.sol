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

interface IBatchMultiplexFeatureV2 {
    /// @dev Routes multiple swaps in a `data` array to the EP.
    /// @notice Non-payable, does not support ETH to tokens calls.
    /// @param data The array of swap transactions.
    /// @return results The array of returned values from the swap calls.
    function batchMultiplexCallV2(bytes[] calldata data) external returns (bytes[] memory results);

    /// @dev Routes multiple swaps in a `data` array to the EP with the desired error behavior.
    /// @notice Non-payable, does not support ETH to tokens calls.
    /// @param data The array of swap transactions.
    /// @param errorBehavior Number of the error behavior type when one of the swaps fails.
    /// @return results The array of returned values from the swap calls.
    function batchMultiplexOptionalParamsCallV2(
        bytes[] calldata data,
        LibTypes.ErrorBehavior errorBehavior
    ) external returns (bytes[] memory results);
}
