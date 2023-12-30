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

/// @dev A sample validator contract for the batck multiplex method.
/// @notice Do not fall for ERC2771 address spoofing attack when implementing validation. The 0x protocol will
///   always verify order signatures for meta transactions from signer regardless who is sending the transactions.
contract BatchMultiplexValidator {
    struct Batch {
        bytes[] calls;
    }

    /// TODO: check how this validation can be skipped, i.e. if the validator input is not as expected.
    /// @dev Validates the data passed from the 0x exchange proxy against the validator's requirements.
    /// @param encodedCalls The swaps in 0x-protocol format.
    /// @param /*extraData*/ An arbitrary string to be used as extra validation.
    /// @param /*sender*/ The address that sent the transaction to the network.
    /// @return isValid Boolean the bundle is valid.
    /// @notice Visibility is `pure` to potentially allow reading from state.
    function validate(
        bytes calldata encodedCalls,
        bytes calldata /*extraData*/,
        address /*sender*/
    ) external view returns (bool isValid) {
        // here the first four bytes of the transaction (the selector) can be extracted and each swap call can
        //  be decoded against its respective 0x-protocol format type.
        Batch memory swaps = abi.decode(encodedCalls, (Batch));
        assert(swaps.calls.length > 0);
        isValid = true;
    }
}
