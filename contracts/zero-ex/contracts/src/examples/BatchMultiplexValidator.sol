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

pragma solidity ^0.8.19;

/// @dev A sample validator contract for the batck multiplex method.
/// @notice Do not fall for ERC2771 address spoofing attack when implementing validation. The 0x protocol will
///   always verify order signatures for meta transactions from signer regardless who is sending the transactions.
contract BatchMultiplexValidator {

    struct MockType {
        address caller;
    }

    // TODO: check if sender address should be appended as last 20 bytes of extraData, which would require extra
    //  gas consumption for address decoding.
    function validate(
        bytes[] calldata calls,
        bytes calldata /*extraData*/,
        address /*sender*/
    ) external pure returns (bool isValid) {
        assert(calls.length > 0);
        isValid = true;
    }

    // TODO: we should only implement 1 standard. The former has more explicit inputs and does not require sender
    //  decoding, while the latter is the encoded package of the previous params and potentially more params.
    function validate(bytes calldata dataPackage) external view returns (bool isValid) {
        MockType memory mockType = MockType(abi.decode(dataPackage, (address)));
        assert(mockType.caller == msg.sender);
        isValid = true;
    }
}
