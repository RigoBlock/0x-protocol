// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import {LocalTest} from "utils/LocalTest.sol";
import {MultiplexUtils} from "utils/MultiplexUtils.sol";
import {LibCommonRichErrors} from "src/errors/LibCommonRichErrors.sol";
import {LibOwnableRichErrors} from "src/errors/LibOwnableRichErrors.sol";
import {LibSignature} from "src/features/libs/LibSignature.sol";
import {LibNativeOrder} from "src/features/libs/LibNativeOrder.sol";
import {IBatchMultiplexFeature} from "src/features/interfaces/IBatchMultiplexFeature.sol";
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

    function _executeBatchMultiplexTransactions(bytes[] memory callData) private {
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

    function test_batchMultiplexMetaTransaction() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        rfqOrder.taker = otherSignerAddress;
        _mintTo(address(rfqOrder.takerToken), otherSignerAddress, rfqOrder.takerAmount);

        IMetaTransactionsFeatureV2.MetaTransactionDataV2 memory mtx;
        LibSignature.Signature memory sig;
        (mtx, sig) = _makeMetaTransactionV2(abi.encodeWithSelector(
            zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken.selector,
            dai,
            zrx,
            _makeArray(_makeRfqSubcall(rfqOrder)),
            rfqOrder.takerAmount,
            rfqOrder.makerAmount
        ));

        bytes[] memory callsArray = new bytes[](1);
        callsArray[0] = abi.encodeWithSelector(
            zeroExDeployed.zeroEx.executeMetaTransactionV2.selector,
            mtx,
            sig
        );

        _executeBatchMultiplexTransactions(callsArray);
    }

    function test_batchMultiplexExpectRevertWithInternalMethod() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        rfqOrder.taker = otherSignerAddress;
        _mintTo(address(rfqOrder.takerToken), otherSignerAddress, rfqOrder.takerAmount);

        LibSignature.Signature memory sig;
        ( , sig) = _makeMetaTransactionV2(abi.encodeWithSelector(
            zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken.selector,
            dai,
            zrx,
            _makeArray(_makeRfqSubcall(rfqOrder)),
            rfqOrder.takerAmount,
            rfqOrder.makerAmount
        ));

        // test revert onlySelf when calling method directly
        vm.expectRevert(LibCommonRichErrors.OnlyCallableBySelfError(address(this)));
        zeroExDeployed.zeroEx._fillRfqOrder(
            rfqOrder,
            sig,
            rfqOrder.makerAmount,
            rfqOrder.taker,
            true,
            address(this)
        );

        bytes[] memory callsArray = new bytes[](1);
        callsArray[0] = abi.encodeWithSelector(
            zeroExDeployed.zeroEx._fillRfqOrder.selector,
            rfqOrder,
            sig,
            rfqOrder.makerAmount,
            rfqOrder.taker,
            true,
            address(this)
        );

        // TODO: check if the following is acceptable or if there is a workaround
        // The call reverts but Foundry does not return the error of low-level calls. When debugging the error,
        //  the transaction is reverted with the expected error reason.
        //vm.expectRevert(LibCommonRichErrors.OnlyCallableBySelfError(msg.sender));
        vm.expectRevert();
        _executeBatchMultiplexTransactions(callsArray);
    }

    function test_batchMultiplexRoleTakeover() external {

        // should revert when trying to add a selector mapping
        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        zeroExDeployed.zeroEx.extend(bytes4(keccak256("_extendSelf(bytes4,address)")), address(1));

        // will revert as caller is not owner
        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        zeroExDeployed.zeroEx.extend(bytes4(keccak256("_extendSelf(bytes4,address)")), address(1));

        // we try and get same result with batchMultiplex
        bytes memory callData = abi.encodeWithSelector(
            zeroExDeployed.zeroEx.extend.selector,
            bytes4(keccak256("_extendSelf(bytes4,address)")),
            address(1)
        );
        bytes[] memory callsArray = new bytes[](1);
        callsArray[0] = callData;

        // will revert with same error as underlying zeroEx call but Forge won't capture it in low-level call
        //vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError((address(this)), zeroExDeployed.zeroEx.owner()));
        vm.expectRevert();
        _executeBatchMultiplexTransactions(callsArray);

        // TODO: test the following assertiong with multiple calls
        vm.expectRevert();
        zeroExDeployed.zeroEx.batchMultiplex(callsArray, callData, address(0), IBatchMultiplexFeature.ErrorHandling.REVERT);

        // should break on failing transaction but not revert entire transaction
        vm.expectRevert();
        zeroExDeployed.zeroEx.batchMultiplex(callsArray, callData, address(0), IBatchMultiplexFeature.ErrorHandling.STOP);

        // should not revert on failing transaction
        vm.expectRevert();
        zeroExDeployed.zeroEx.batchMultiplex(callsArray, callData, address(0), IBatchMultiplexFeature.ErrorHandling.CONTINUE);
    }
}
