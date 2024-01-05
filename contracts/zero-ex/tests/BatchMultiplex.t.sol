// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import {LocalTest} from "utils/LocalTest.sol";
import {MultiplexUtils} from "utils/MultiplexUtils.sol";
import {LibCommonRichErrors} from "src/errors/LibCommonRichErrors.sol";
import {LibSignature} from "src/features/libs/LibSignature.sol";
import {LibNativeOrder} from "src/features/libs/LibNativeOrder.sol";
import {IMetaTransactionsFeatureV2} from "src/features/interfaces/IMetaTransactionsFeatureV2.sol";

contract BatchMultiplex is LocalTest, MultiplexUtils {
    function _makeMetaTransactionV2(
        bytes memory callData
    ) private view returns (IMetaTransactionsFeatureV2.MetaTransactionDataV2 memory, LibSignature.Signature memory) {
        IMetaTransactionsFeatureV2.MetaTransactionDataV2 memory mtx = IMetaTransactionsFeatureV2.MetaTransactionDataV2({
            signer: payable(otherSignerAddress),
            sender: address(0),
            expirationTimeSeconds: block.timestamp + 600,
            salt: 123,
            callData: callData,
            feeToken: dai,
            fees: new IMetaTransactionsFeatureV2.MetaTransactionFeeData[](0)
        });

        bytes32 mtxHash = zeroExDeployed.zeroEx.getMetaTransactionV2Hash(mtx);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(otherSignerKey, mtxHash);
        LibSignature.Signature memory sig = LibSignature.Signature(LibSignature.SignatureType.EIP712, v, r, s);

        return (mtx, sig);
    }

    function _executeMetaTransaction(bytes memory callData) private {
        IMetaTransactionsFeatureV2.MetaTransactionDataV2 memory mtx;
        LibSignature.Signature memory sig;
        (mtx, sig) = _makeMetaTransactionV2(callData);
        zeroExDeployed.zeroEx.executeMetaTransactionV2(mtx, sig);
    }

    function _executeBatchMultiplexTransactions(bytes[] calldata callData) private {
        zeroExDeployed.zeroEx.batchMultiplex(callData);
    }

    // batch

    function test_metaTransaction_multiplexBatchSellTokenForToken_rfqOrder() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        rfqOrder.taker = otherSignerAddress;
        _mintTo(address(rfqOrder.takerToken), otherSignerAddress, rfqOrder.takerAmount);

        _executeMetaTransaction(
            abi.encodeWithSelector(
                zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken.selector,
                dai,
                zrx,
                _makeArray(_makeRfqSubcall(rfqOrder)),
                rfqOrder.takerAmount,
                rfqOrder.makerAmount
            )
        );
    }

    function test_batchMultiplex() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        rfqOrder.taker = otherSignerAddress;
        _mintTo(address(rfqOrder.takerToken), otherSignerAddress, rfqOrder.takerAmount);

        _executeBatchMultiplexTransactions(
            [
                abi.encodeWithSelector(
                    zeroExDeployed.zeroEx.executeMetaTransactionV2,
                    abi.encodeWithSelector(
                        zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken.selector,
                        dai,
                        zrx,
                        _makeArray(_makeRfqSubcall(rfqOrder)),
                        rfqOrder.takerAmount,
                        rfqOrder.makerAmount
                    )
                )
            ]
        );
    }

    function test_batchMultiplexExpectRevertWithInternalMethod() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        rfqOrder.taker = otherSignerAddress;
        _mintTo(address(rfqOrder.takerToken), otherSignerAddress, rfqOrder.takerAmount);

        // inputs won't match, we need to correctly encode params
        _executeBatchMultiplexTransactions(
            [
                abi.encodeWithSelector(
                    zeroExDeployed.zeroEx._fillRfqOrder.selector,
                    _makeArray(_makeRfqSubcall(rfqOrder))
                )
            ]
        );

        /*LibNativeOrder.RfqOrder memory order,
        LibSignature.Signature memory signature,
        uint128 takerTokenFillAmount,
        address taker,
        bool useSelfBalance,
        address recipient*/

        vm.expectRevert(LibCommonRichErrors.OnlyCallableBySelfError(address(this)));
        /*_executeBatchMultiplexTransactions(
            [
                abi.encodeWithSelector(
                    zeroExDeployed.zeroEx.fillRfqOrder.selector,
                    _makeArray(_makeRfqSubcall(rfqOrder))
                )
            ]
        );*/

        // should revert when trying to add a selector mapping
        _executeBatchMultiplexTransactions(
            [
                abi.encodeWithSelector(
                    zeroExDeployed.zeroEx._extendSelf.selector,
                    zeroExDeployed.zeroEx._extendSelf.selector,
                    address(1)
                )
            ]
        );

        vm.expectRevert(LibCommonRichErrors.OnlyCallableBySelfError(address(this)));
    }
}
