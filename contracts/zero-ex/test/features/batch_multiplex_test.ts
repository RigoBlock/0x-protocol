import {
    blockchainTests,
    constants,
    expect,
    getRandomInteger,
    randomAddress,
    verifyEventsFromLogs,
} from '@0x/contracts-test-utils';
import { MetaTransaction, MetaTransactionFields } from '@0x/protocol-utils';
import { BigNumber, hexUtils, StringRevertError, ZeroExRevertErrors } from '@0x/utils';
import * as _ from 'lodash';

import { BatchMultiplexFeatureContract, IZeroExContract, MetaTransactionsFeatureContract } from '../../src/wrappers';
import { artifacts } from '../artifacts';
import { abis } from '../utils/abis';
import { fullMigrateAsync } from '../utils/migration';
import { getRandomLimitOrder, getRandomRfqOrder } from '../utils/orders';
import {
    TestMetaTransactionsNativeOrdersFeatureContract,
    TestMetaTransactionsNativeOrdersFeatureEvents,
    TestMetaTransactionsTransformERC20FeatureContract,
    TestMetaTransactionsTransformERC20FeatureEvents,
    TestMintableERC20TokenContract,
    TestWethContract,
} from '../wrappers';

const { NULL_ADDRESS, ZERO_AMOUNT } = constants;

// TODO: rewrite test with direct methods, or simply transfer to foundry tests which will be
//  included in coverage report.
blockchainTests.resets('BatchMultiplex feature', env => {
    let owner: string;
    let maker: string;
    let sender: string;
    let notSigner: string;
    const signers: string[] = [];
    let zeroEx: IZeroExContract;
    let metaTransactionsFeature: MetaTransactionsFeatureContract;
    let batchMultiplexFeature: BatchMultiplexFeatureContract;
    let feeToken: TestMintableERC20TokenContract;
    let weth: TestWethContract;
    let transformERC20Feature: TestMetaTransactionsTransformERC20FeatureContract;
    let nativeOrdersFeature: TestMetaTransactionsNativeOrdersFeatureContract;

    const MAX_FEE_AMOUNT = new BigNumber('1e18');
    const TRANSFORM_ERC20_ONE_WEI_VALUE = new BigNumber(555);
    const TRANSFORM_ERC20_FAILING_VALUE = new BigNumber(666);
    const TRANSFORM_ERC20_REENTER_VALUE = new BigNumber(777);
    const TRANSFORM_ERC20_BATCH_REENTER_VALUE = new BigNumber(888);
    const REENTRANCY_FLAG_MTX = 0x1;
    const REENTRANCY_FLAG_BATCH_MULTIPLEX = 0x2;

    before(async () => {
        let possibleSigners: string[];
        [owner, maker, sender, notSigner, ...possibleSigners] = await env.getAccountAddressesAsync();
        transformERC20Feature = await TestMetaTransactionsTransformERC20FeatureContract.deployFrom0xArtifactAsync(
            artifacts.TestMetaTransactionsTransformERC20Feature,
            env.provider,
            env.txDefaults,
            {},
        );
        nativeOrdersFeature = await TestMetaTransactionsNativeOrdersFeatureContract.deployFrom0xArtifactAsync(
            artifacts.TestMetaTransactionsNativeOrdersFeature,
            env.provider,
            env.txDefaults,
            {},
        );
        weth = await TestWethContract.deployFrom0xArtifactAsync(
            artifacts.TestWeth,
            env.provider,
            env.txDefaults,
            artifacts,
        );
        batchMultiplexFeature = await BatchMultiplexFeatureContract.deployFrom0xArtifactAsync(
            artifacts.BatchMultiplexFeature,
            env.provider,
            env.txDefaults,
            artifacts,
            weth.address,
        );
        zeroEx = await fullMigrateAsync(owner, env.provider, env.txDefaults, {
            transformERC20: transformERC20Feature.address,
            nativeOrders: nativeOrdersFeature.address,
            batchMultiplex: batchMultiplexFeature.address,
        });
        zeroEx = new IZeroExContract(zeroEx.address, env.provider, { ...env.txDefaults, from: sender }, abis);
        metaTransactionsFeature = new MetaTransactionsFeatureContract(
            zeroEx.address,
            env.provider,
            { ...env.txDefaults, from: sender },
            abis,
        );
        feeToken = await TestMintableERC20TokenContract.deployFrom0xArtifactAsync(
            artifacts.TestMintableERC20Token,
            env.provider,
            env.txDefaults,
            {},
        );

        // some accounts returned can be unfunded
        for (const possibleSigner of possibleSigners) {
            const balance = await env.web3Wrapper.getBalanceInWeiAsync(possibleSigner);
            if (balance.isGreaterThan(0)) {
                signers.push(possibleSigner);
                await feeToken
                    .approve(zeroEx.address, MAX_FEE_AMOUNT)
                    .awaitTransactionSuccessAsync({ from: possibleSigner });
                await feeToken.mint(possibleSigner, MAX_FEE_AMOUNT).awaitTransactionSuccessAsync();
            }
        }
    });

    function getRandomMetaTransaction(fields: Partial<MetaTransactionFields> = {}): MetaTransaction {
        return new MetaTransaction({
            signer: _.sampleSize(signers)[0],
            sender,
            // TODO: dekz Ganache gasPrice opcode is returning 0, cannot influence it up to test this case
            minGasPrice: ZERO_AMOUNT,
            maxGasPrice: getRandomInteger('1e9', '100e9'),
            expirationTimeSeconds: new BigNumber(Math.floor(_.now() / 1000) + 360),
            salt: new BigNumber(hexUtils.random()),
            callData: hexUtils.random(4),
            value: getRandomInteger(1, '1e18'),
            feeToken: feeToken.address,
            feeAmount: getRandomInteger(1, MAX_FEE_AMOUNT),
            chainId: 1337,
            verifyingContract: zeroEx.address,
            ...fields,
        });
    }

    interface TransformERC20Args {
        inputToken: string;
        outputToken: string;
        inputTokenAmount: BigNumber;
        minOutputTokenAmount: BigNumber;
        transformations: Array<{ deploymentNonce: BigNumber; data: string }>;
    }

    function getRandomTransformERC20Args(fields: Partial<TransformERC20Args> = {}): TransformERC20Args {
        return {
            inputToken: randomAddress(),
            outputToken: randomAddress(),
            inputTokenAmount: getRandomInteger(1, '1e18'),
            minOutputTokenAmount: getRandomInteger(1, '1e18'),
            transformations: [{ deploymentNonce: new BigNumber(123), data: hexUtils.random() }],
            ...fields,
        };
    }

    const RAW_TRANSFORM_SUCCESS_RESULT = hexUtils.leftPad(1337);
    const RAW_ORDER_SUCCESS_RESULT = hexUtils.leftPad(1337, 64);

    describe('batchMultiplexCall(executeMetaTransaction())', () => {
        it('can call NativeOrders.fillLimitOrder()', async () => {
            const order = getRandomLimitOrder({ maker });
            const fillAmount = new BigNumber(23456);
            const sig = await order.getSignatureWithProviderAsync(env.provider);
            const mtx = getRandomMetaTransaction({
                callData: nativeOrdersFeature.fillLimitOrder(order, sig, fillAmount).getABIEncodedTransactionData(),
            });
            const signature = await mtx.getSignatureWithProviderAsync(env.provider);
            // TODO: with multiple eth -> token calls, txn will fail unless eth -> weth & erc20 -> [erc20, erc20]
            const callOpts = {
                gasPrice: mtx.minGasPrice,
                value: mtx.value,
            };

            const metaCallData = metaTransactionsFeature
                .executeMetaTransaction(mtx, signature)
                .getABIEncodedTransactionData();
            const tx = batchMultiplexFeature.batchMultiplexCall([metaCallData]).awaitTransactionSuccessAsync(callOpts);
            expect(tx).to.revertWith('Batch_M_Feat/DIRECT_CALL_ERROR');
            const rawResult = await zeroEx.batchMultiplexCall([metaCallData]).callAsync(callOpts);
            expect(hexUtils.slice(rawResult[0], 64)).to.eq(RAW_ORDER_SUCCESS_RESULT);
            const receipt = await zeroEx.batchMultiplexCall([metaCallData]).awaitTransactionSuccessAsync(callOpts);

            verifyEventsFromLogs(
                receipt.logs,
                [
                    {
                        order: _.omit(order, ['verifyingContract', 'chainId']),
                        sender: mtx.sender,
                        taker: mtx.signer,
                        takerTokenFillAmount: fillAmount,
                        signatureType: sig.signatureType,
                        v: sig.v,
                        r: sig.r,
                        s: sig.s,
                    },
                ],
                TestMetaTransactionsNativeOrdersFeatureEvents.FillLimitOrderCalled,
            );
        });

        it('can call NativeOrders.fillRfqOrder()', async () => {
            const order = getRandomRfqOrder({ maker });
            const sig = await order.getSignatureWithProviderAsync(env.provider);
            const fillAmount = new BigNumber(23456);
            const mtx = getRandomMetaTransaction({
                callData: nativeOrdersFeature.fillRfqOrder(order, sig, fillAmount).getABIEncodedTransactionData(),
                value: ZERO_AMOUNT,
            });
            const signature = await mtx.getSignatureWithProviderAsync(env.provider);
            const callOpts = {
                gasPrice: mtx.minGasPrice,
                value: 0,
            };
            const metaCallData = metaTransactionsFeature
                .executeMetaTransaction(mtx, signature)
                .getABIEncodedTransactionData();
            const tx = batchMultiplexFeature.batchMultiplexCall([metaCallData]).awaitTransactionSuccessAsync(callOpts);
            expect(tx).to.revertWith('Batch_M_Feat/DIRECT_CALL_ERROR');
            const rawResult = await zeroEx.batchMultiplexCall([metaCallData]).callAsync(callOpts);
            expect(hexUtils.slice(rawResult[0], 64)).to.eq(RAW_ORDER_SUCCESS_RESULT);
            const receipt = await zeroEx.batchMultiplexCall([metaCallData]).awaitTransactionSuccessAsync(callOpts);

            verifyEventsFromLogs(
                receipt.logs,
                [
                    {
                        order: _.omit(order, ['verifyingContract', 'chainId']),
                        taker: mtx.signer,
                        takerTokenFillAmount: fillAmount,
                        signatureType: sig.signatureType,
                        v: sig.v,
                        r: sig.r,
                        s: sig.s,
                    },
                ],
                TestMetaTransactionsNativeOrdersFeatureEvents.FillRfqOrderCalled,
            );
        });

        it('can call `TransformERC20.transformERC20()`', async () => {
            const args = getRandomTransformERC20Args();
            const mtx = getRandomMetaTransaction({
                callData: transformERC20Feature
                    .transformERC20(
                        args.inputToken,
                        args.outputToken,
                        args.inputTokenAmount,
                        args.minOutputTokenAmount,
                        args.transformations,
                    )
                    .getABIEncodedTransactionData(),
            });
            const signature = await mtx.getSignatureWithProviderAsync(env.provider);
            const callOpts = {
                gasPrice: mtx.minGasPrice,
                value: mtx.value,
            };
            const metaCallData = metaTransactionsFeature
                .executeMetaTransaction(mtx, signature)
                .getABIEncodedTransactionData();
            const tx = batchMultiplexFeature.batchMultiplexCall([metaCallData]).awaitTransactionSuccessAsync(callOpts);
            expect(tx).to.revertWith('Batch_M_Feat/DIRECT_CALL_ERROR');
            const rawResult = await zeroEx.batchMultiplexCall([metaCallData]).callAsync(callOpts);
            expect(hexUtils.slice(rawResult[0], 64)).to.eq(RAW_TRANSFORM_SUCCESS_RESULT);
            const receipt = await zeroEx.batchMultiplexCall([metaCallData]).awaitTransactionSuccessAsync(callOpts);

            verifyEventsFromLogs(
                receipt.logs,
                [
                    {
                        inputToken: args.inputToken,
                        outputToken: args.outputToken,
                        inputTokenAmount: args.inputTokenAmount,
                        minOutputTokenAmount: args.minOutputTokenAmount,
                        transformations: args.transformations,
                        sender: zeroEx.address,
                        value: mtx.value,
                        taker: mtx.signer,
                    },
                ],
                TestMetaTransactionsTransformERC20FeatureEvents.TransformERC20Called,
            );
        });

        it('can call `TransformERC20.transformERC20()` with calldata', async () => {
            const args = getRandomTransformERC20Args();
            const callData = transformERC20Feature
                .transformERC20(
                    args.inputToken,
                    args.outputToken,
                    args.inputTokenAmount,
                    args.minOutputTokenAmount,
                    args.transformations,
                )
                .getABIEncodedTransactionData();
            const mtx = getRandomMetaTransaction({ callData });
            const signature = await mtx.getSignatureWithProviderAsync(env.provider);
            const callOpts = {
                gasPrice: mtx.minGasPrice,
                value: mtx.value,
            };
            const metaCallData = metaTransactionsFeature
                .executeMetaTransaction(mtx, signature)
                .getABIEncodedTransactionData();
            const tx = batchMultiplexFeature.batchMultiplexCall([metaCallData]).awaitTransactionSuccessAsync(callOpts);
            expect(tx).to.revertWith('Batch_M_Feat/DIRECT_CALL_ERROR');
            const rawResult = await zeroEx.batchMultiplexCall([metaCallData]).callAsync(callOpts);
            expect(hexUtils.slice(rawResult[0], 64)).to.eq(RAW_TRANSFORM_SUCCESS_RESULT);
            const receipt = await zeroEx.batchMultiplexCall([metaCallData]).awaitTransactionSuccessAsync(callOpts);

            verifyEventsFromLogs(
                receipt.logs,
                [
                    {
                        inputToken: args.inputToken,
                        outputToken: args.outputToken,
                        inputTokenAmount: args.inputTokenAmount,
                        minOutputTokenAmount: args.minOutputTokenAmount,
                        transformations: args.transformations,
                        sender: zeroEx.address,
                        value: mtx.value,
                        taker: mtx.signer,
                    },
                ],
                TestMetaTransactionsTransformERC20FeatureEvents.TransformERC20Called,
            );
        });

        it('fails if the translated call fails', async () => {
            const args = getRandomTransformERC20Args();
            const mtx = getRandomMetaTransaction({
                value: new BigNumber(TRANSFORM_ERC20_FAILING_VALUE),
                callData: transformERC20Feature
                    .transformERC20(
                        args.inputToken,
                        args.outputToken,
                        args.inputTokenAmount,
                        args.minOutputTokenAmount,
                        args.transformations,
                    )
                    .getABIEncodedTransactionData(),
            });
            const mtxHash = mtx.getHash();
            const signature = await mtx.getSignatureWithProviderAsync(env.provider);
            const callOpts = {
                gasPrice: mtx.minGasPrice,
                value: mtx.value,
            };
            const metaCallData = metaTransactionsFeature
                .executeMetaTransaction(mtx, signature)
                .getABIEncodedTransactionData();
            const tx = zeroEx.batchMultiplexCall([metaCallData]).callAsync(callOpts);
            const actualCallData = transformERC20Feature
                ._transformERC20({
                    taker: mtx.signer,
                    inputToken: args.inputToken,
                    outputToken: args.outputToken,
                    inputTokenAmount: args.inputTokenAmount,
                    minOutputTokenAmount: args.minOutputTokenAmount,
                    transformations: args.transformations,
                    useSelfBalance: false,
                    recipient: mtx.signer,
                })
                .getABIEncodedTransactionData();
            return expect(tx).to.revertWith(
                new ZeroExRevertErrors.MetaTransactions.MetaTransactionCallFailedError(
                    mtxHash,
                    actualCallData,
                    new StringRevertError('FAIL').encode(),
                ),
            );
        });

        it('fails when calling an onlySelf-restricted method', async () => {
            const args = getRandomTransformERC20Args();
            const externalMtx = getRandomMetaTransaction({
                value: new BigNumber(TRANSFORM_ERC20_FAILING_VALUE),
                callData: transformERC20Feature
                    .transformERC20(
                        args.inputToken,
                        args.outputToken,
                        args.inputTokenAmount,
                        args.minOutputTokenAmount,
                        args.transformations,
                    )
                    .getABIEncodedTransactionData(),
            });
            const mtx = getRandomMetaTransaction({
                value: externalMtx.value,
                callData: transformERC20Feature
                    ._transformERC20({
                        taker: externalMtx.signer,
                        inputToken: args.inputToken,
                        outputToken: args.outputToken,
                        inputTokenAmount: args.inputTokenAmount,
                        minOutputTokenAmount: args.minOutputTokenAmount,
                        transformations: args.transformations,
                        useSelfBalance: false,
                        recipient: externalMtx.signer,
                    })
                    .getABIEncodedTransactionData(),
            });
            const mtxHash = mtx.getHash();
            const signature = await mtx.getSignatureWithProviderAsync(env.provider);
            const callOpts = {
                gasPrice: mtx.minGasPrice,
                value: mtx.value,
            };
            const metaCallData = metaTransactionsFeature
                .executeMetaTransaction(mtx, signature)
                .getABIEncodedTransactionData();
            const tx1 = zeroEx.batchMultiplexCall([metaCallData]).callAsync(callOpts);
            return expect(tx1).to.revertWith(
                new ZeroExRevertErrors.MetaTransactions.MetaTransactionUnsupportedFunctionError(
                    mtxHash,
                    hexUtils.slice(mtx.callData, 0, 4),
                ),
            );
            const callData = transformERC20Feature
                .transformERC20(
                    args.inputToken,
                    args.outputToken,
                    args.inputTokenAmount,
                    args.minOutputTokenAmount,
                    args.transformations,
                )
                .getABIEncodedTransactionData();
            const tx2 = zeroEx.batchMultiplexCall([callData]).callAsync(callOpts);
            return expect(tx2).to.revertWith(
                new ZeroExRevertErrors.Common.OnlyCallableBySelfError(env.txDefaults.from),
            );
        });

        it('cannot reenter `executeMetaTransaction()`', async () => {
            const args = getRandomTransformERC20Args();
            const mtx = getRandomMetaTransaction({
                callData: transformERC20Feature
                    .transformERC20(
                        args.inputToken,
                        args.outputToken,
                        args.inputTokenAmount,
                        args.minOutputTokenAmount,
                        args.transformations,
                    )
                    .getABIEncodedTransactionData(),
                value: TRANSFORM_ERC20_REENTER_VALUE,
            });
            const mtxHash = mtx.getHash();
            const signature = await mtx.getSignatureWithProviderAsync(env.provider);
            const callOpts = {
                gasPrice: mtx.maxGasPrice,
                value: mtx.value,
            };
            const metaCallData = metaTransactionsFeature
                .executeMetaTransaction(mtx, signature)
                .getABIEncodedTransactionData();
            const encodedBatchTransaction = batchMultiplexFeature
                .batchMultiplexCall([metaCallData])
                .getABIEncodedTransactionData();
            const tx = zeroEx.batchMultiplexCall([encodedBatchTransaction]).callAsync(callOpts);
            return expect(tx).to.revertWith(
                new ZeroExRevertErrors.Common.IllegalReentrancyError(
                    batchMultiplexFeature.getSelector('batchMultiplexCall'),
                    REENTRANCY_FLAG_BATCH_MULTIPLEX,
                ),
            );
            const tx2 = zeroEx.batchMultiplexCall([metaCallData, metaCallData]).callAsync(callOpts);
            return expect(tx).to.revertWith(
                new ZeroExRevertErrors.Common.IllegalReentrancyError(
                    metaTransactionsFeature.getSelector('executeMetaTransaction'),
                    REENTRANCY_FLAG_MTX,
                ),
            );
        });
    });
});
