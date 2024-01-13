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

// This interface is inherited by IZeroEx, which compiles with pragma ^0.6.5
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

// TODO: assert that publicly exposed internal methods revert when called with batchMultiplex(...args)
interface IBatchMultiplexFeature {
    enum ErrorHandling {
        REVERT,
        STOP,
        CONTINUE
    }

    /// @dev Routes the swaps in the `data` array to their respective swap implementations.
    /// @param data The array of swap transactions.
    /// @return results The array of returned values from the swap calls.
    function batchMultiplex(bytes[] calldata data) external payable returns (bytes[] memory results);

    /// @dev Routes the swaps in the `data` array to their respective swap implementations after
    ///   validating them in an external validator contract and passes extra data to it.
    /// @param data The array of swap transactions.
    /// @param extraData A string of extra data for project-specific validation.
    /// @param validatorAddress The address of the validator contract.
    /// @return results The array of returned values from the swap calls.
    function batchMultiplex(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress
    ) external payable returns (bytes[] memory results);

    /// @dev Routes the swaps in the `data` array to their respective swap implementations after
    ///   validating them in an external validator contract and passes extra data and the desired error behavior.
    /// @param data The array of swap transactions.
    /// @param extraData A string of extra data for project-specific validation.
    /// @param validatorAddress The address of the validator contract.
    /// @param errorType Number of the error behavior type when one of the swaps fails.
    /// @return results The array of returned values from the swap calls.
    function batchMultiplex(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress,
        ErrorHandling errorType
    ) external payable returns (bytes[] memory results);
}
