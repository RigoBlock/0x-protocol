// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import {LocalTest} from "utils/LocalTest.sol";
import {MultiplexUtils} from "utils/MultiplexUtils.sol";
import {LibCommonRichErrors} from "src/errors/LibCommonRichErrors.sol";
import {LibOwnableRichErrors} from "src/errors/LibOwnableRichErrors.sol";
import {BatchMultiplexValidator} from "src/examples/BatchMultiplexValidator.sol";
import {LibSignature} from "src/features/libs/LibSignature.sol";
import {LibNativeOrder} from "src/features/libs/LibNativeOrder.sol";
import {IBatchMultiplexFeature} from "src/features/interfaces/IBatchMultiplexFeature.sol";
import {IMetaTransactionsFeatureV2} from "src/features/interfaces/IMetaTransactionsFeatureV2.sol";

interface IMockBM {
    enum ErrorHandling {
        REVERT,
        STOP,
        CONTINUE,
        UNKNOWN
    }

    function batchMultiplexOptionalParams(
        bytes[] calldata data,
        bytes calldata extraData,
        address validatorAddress,
        ErrorHandling errorType
    ) external payable returns (bytes[] memory results);
}

contract BatchMultiplex is LocalTest, MultiplexUtils {
    event RfqOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        bytes32 pool
    );

    address public immutable _validator;

    constructor() public {
        _validator = address(new BatchMultiplexValidator());
    }

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
        (mtx, sig) = _makeMetaTransactionV2(
            abi.encodeWithSelector(
                zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken.selector,
                dai,
                zrx,
                _makeArray(_makeRfqSubcall(rfqOrder)),
                rfqOrder.takerAmount,
                rfqOrder.makerAmount
            )
        );

        bytes[] memory callsArray = new bytes[](1);
        callsArray[0] = abi.encodeWithSelector(zeroExDeployed.zeroEx.executeMetaTransactionV2.selector, mtx, sig);

        // direct call to implementation is not allowed
        vm.expectRevert("Batch_M_Feat/DIRECT_CALL_ERROR");
        zeroExDeployed.features.batchMultiplexFeature.batchMultiplex(callsArray);

        _executeBatchMultiplexTransactions(callsArray);
    }

    function test_batchMultiplexExpectRevertWithInternalMethod() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        rfqOrder.taker = otherSignerAddress;
        _mintTo(address(rfqOrder.takerToken), otherSignerAddress, rfqOrder.takerAmount);

        LibSignature.Signature memory sig;
        (, sig) = _makeMetaTransactionV2(
            abi.encodeWithSelector(
                zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken.selector,
                dai,
                zrx,
                _makeArray(_makeRfqSubcall(rfqOrder)),
                rfqOrder.takerAmount,
                rfqOrder.makerAmount
            )
        );

        // test revert onlySelf when calling method directly
        vm.expectRevert(LibCommonRichErrors.OnlyCallableBySelfError(address(this)));
        zeroExDeployed.zeroEx._fillRfqOrder(rfqOrder, sig, rfqOrder.makerAmount, rfqOrder.taker, true, address(this));

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

        vm.expectRevert(LibCommonRichErrors.OnlyCallableBySelfError(address(this)));
        _executeBatchMultiplexTransactions(callsArray);
    }

    function test_batchMultiplexRoleTakeover() external {
        // should revert when trying to add a selector mapping
        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        zeroExDeployed.zeroEx.extend(bytes4(keccak256("_extendSelf(bytes4,address)")), address(1));

        // we try and get same result with batchMultiplex
        bytes[] memory callsArray = new bytes[](1);
        callsArray[0] = abi.encodeWithSelector(
            zeroExDeployed.zeroEx.extend.selector,
            bytes4(keccak256("_extendSelf(bytes4,address)")),
            address(1)
        );

        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        _executeBatchMultiplexTransactions(callsArray);

        // TODO: test the following assertiong with multiple calls
        bytes memory mockBytes = callsArray[0];
        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        zeroExDeployed.zeroEx.batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IBatchMultiplexFeature.ErrorHandling.REVERT
        );

        // does not extend but does stops instead of reverting
        zeroExDeployed.zeroEx.batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IBatchMultiplexFeature.ErrorHandling.STOP
        );

        // does not extend but tries to continue exeuting next txns
        zeroExDeployed.zeroEx.batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IBatchMultiplexFeature.ErrorHandling.CONTINUE
        );
    }

    function test_batchMultiplexUnknownRevertError() external {
        bytes[] memory callsArray = new bytes[](1);
        callsArray[0] = abi.encodeWithSelector(
            zeroExDeployed.zeroEx.extend.selector,
            bytes4(keccak256("_extendSelf(bytes4,address)")),
            address(1)
        );
        bytes memory mockBytes = callsArray[0];

        bytes memory unknownRevertCalldata = abi.encodeWithSelector(
            IBatchMultiplexFeature.batchMultiplexOptionalParams.selector,
            callsArray,
            mockBytes,
            address(0),
            IMockBM.ErrorHandling.UNKNOWN
        );
        vm.expectRevert();
        (bool revertsAsExpected, ) = address(zeroExDeployed.zeroEx).call(unknownRevertCalldata);
        assertTrue(revertsAsExpected, "expectRevert: call did not revert");

        // TODO: not sure EVM returns the expected error when a different enum type is used, will not be
        //  able to reproduce error in coverage
        vm.expectRevert();
        IMockBM(address(zeroExDeployed.zeroEx)).batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IMockBM.ErrorHandling.UNKNOWN
        );

        vm.expectRevert(LibOwnableRichErrors.OnlyOwnerError(address(this), zeroExDeployed.zeroEx.owner()));
        IMockBM(address(zeroExDeployed.zeroEx)).batchMultiplexOptionalParams(
            callsArray,
            mockBytes,
            address(0),
            IMockBM.ErrorHandling.REVERT
        );
    }

    function test_batchMutiplexTransaction_batchMultiplex_rfqOrderFallbackUniswapV2() external {
        LibNativeOrder.RfqOrder memory rfqOrder = _makeTestRfqOrder();
        _createUniswapV2Pool(uniV2Factory, dai, zrx, 10e18, 10e18);
        _mintTo(address(rfqOrder.takerToken), rfqOrder.taker, 10 * rfqOrder.takerAmount);

        (bytes memory callData, LibSignature.Signature memory sig) = _makeRfqSubcallForBatch(
            rfqOrder,
            rfqOrder.takerAmount
        );
        _mintTo(address(dai), otherSignerAddress, 2e18);

        bytes memory uniswapV2FallbackData = abi.encodeWithSelector(
            zeroExDeployed.zeroEx.multiplexBatchSellTokenForToken.selector,
            dai,
            zrx,
            _makeArray(_makeUniswapV2BatchSubcall(_makeArray(address(dai), address(zrx)), 2 * 1e18, false)),
            1e18,
            0
        );

        vm.expectEmit(true, true, true, true);
        emit RfqOrderFilled(
            zeroExDeployed.features.nativeOrdersFeature.getRfqOrderHash(rfqOrder),
            rfqOrder.maker,
            rfqOrder.taker,
            address(rfqOrder.makerToken),
            address(rfqOrder.takerToken),
            rfqOrder.takerAmount,
            rfqOrder.makerAmount,
            rfqOrder.pool
        );

        _executeBatchMultiplexTransactions(_makeArray(callData, uniswapV2FallbackData));
    }
}
