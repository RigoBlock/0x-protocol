/*
 * -----------------------------------------------------------------------------
 * Warning: This file is auto-generated by contracts-gen. Don't edit manually.
 * -----------------------------------------------------------------------------
 */
import { ContractArtifact } from 'ethereum-types';

import * as AbstractBridgeAdapter from '../test/generated-artifacts/AbstractBridgeAdapter.json';
import * as AffiliateFeeTransformer from '../test/generated-artifacts/AffiliateFeeTransformer.json';
import * as ArbitrumBridgeAdapter from '../test/generated-artifacts/ArbitrumBridgeAdapter.json';
import * as AvalancheBridgeAdapter from '../test/generated-artifacts/AvalancheBridgeAdapter.json';
import * as BaseBridgeAdapter from '../test/generated-artifacts/BaseBridgeAdapter.json';
import * as BaseGoerliBridgeAdapter from '../test/generated-artifacts/BaseGoerliBridgeAdapter.json';
import * as BatchFillNativeOrdersFeature from '../test/generated-artifacts/BatchFillNativeOrdersFeature.json';
import * as BatchMultiplexFeature from '../test/generated-artifacts/BatchMultiplexFeature.json';
import * as BatchMultiplexValidator from '../test/generated-artifacts/BatchMultiplexValidator.json';
import * as BootstrapFeature from '../test/generated-artifacts/BootstrapFeature.json';
import * as BridgeProtocols from '../test/generated-artifacts/BridgeProtocols.json';
import * as BSCBridgeAdapter from '../test/generated-artifacts/BSCBridgeAdapter.json';
import * as CeloBridgeAdapter from '../test/generated-artifacts/CeloBridgeAdapter.json';
import * as CurveLiquidityProvider from '../test/generated-artifacts/CurveLiquidityProvider.json';
import * as ERC1155OrdersFeature from '../test/generated-artifacts/ERC1155OrdersFeature.json';
import * as ERC165Feature from '../test/generated-artifacts/ERC165Feature.json';
import * as ERC721OrdersFeature from '../test/generated-artifacts/ERC721OrdersFeature.json';
import * as EthereumBridgeAdapter from '../test/generated-artifacts/EthereumBridgeAdapter.json';
import * as FantomBridgeAdapter from '../test/generated-artifacts/FantomBridgeAdapter.json';
import * as FeeCollector from '../test/generated-artifacts/FeeCollector.json';
import * as FeeCollectorController from '../test/generated-artifacts/FeeCollectorController.json';
import * as FillQuoteTransformer from '../test/generated-artifacts/FillQuoteTransformer.json';
import * as FixinCommon from '../test/generated-artifacts/FixinCommon.json';
import * as FixinEIP712 from '../test/generated-artifacts/FixinEIP712.json';
import * as FixinERC1155Spender from '../test/generated-artifacts/FixinERC1155Spender.json';
import * as FixinERC721Spender from '../test/generated-artifacts/FixinERC721Spender.json';
import * as FixinProtocolFees from '../test/generated-artifacts/FixinProtocolFees.json';
import * as FixinReentrancyGuard from '../test/generated-artifacts/FixinReentrancyGuard.json';
import * as FixinTokenSpender from '../test/generated-artifacts/FixinTokenSpender.json';
import * as FlashWallet from '../test/generated-artifacts/FlashWallet.json';
import * as FullMigration from '../test/generated-artifacts/FullMigration.json';
import * as FundRecoveryFeature from '../test/generated-artifacts/FundRecoveryFeature.json';
import * as IBatchFillNativeOrdersFeature from '../test/generated-artifacts/IBatchFillNativeOrdersFeature.json';
import * as IBatchMultiplexFeature from '../test/generated-artifacts/IBatchMultiplexFeature.json';
import * as IBootstrapFeature from '../test/generated-artifacts/IBootstrapFeature.json';
import * as IBridgeAdapter from '../test/generated-artifacts/IBridgeAdapter.json';
import * as IERC1155OrdersFeature from '../test/generated-artifacts/IERC1155OrdersFeature.json';
import * as IERC1155Token from '../test/generated-artifacts/IERC1155Token.json';
import * as IERC165Feature from '../test/generated-artifacts/IERC165Feature.json';
import * as IERC20Bridge from '../test/generated-artifacts/IERC20Bridge.json';
import * as IERC20Transformer from '../test/generated-artifacts/IERC20Transformer.json';
import * as IERC721OrdersFeature from '../test/generated-artifacts/IERC721OrdersFeature.json';
import * as IERC721Token from '../test/generated-artifacts/IERC721Token.json';
import * as IFeature from '../test/generated-artifacts/IFeature.json';
import * as IFeeRecipient from '../test/generated-artifacts/IFeeRecipient.json';
import * as IFlashWallet from '../test/generated-artifacts/IFlashWallet.json';
import * as IFundRecoveryFeature from '../test/generated-artifacts/IFundRecoveryFeature.json';
import * as ILiquidityProvider from '../test/generated-artifacts/ILiquidityProvider.json';
import * as ILiquidityProviderFeature from '../test/generated-artifacts/ILiquidityProviderFeature.json';
import * as ILiquidityProviderSandbox from '../test/generated-artifacts/ILiquidityProviderSandbox.json';
import * as IMetaTransactionsFeature from '../test/generated-artifacts/IMetaTransactionsFeature.json';
import * as IMetaTransactionsFeatureV2 from '../test/generated-artifacts/IMetaTransactionsFeatureV2.json';
import * as IMooniswapPool from '../test/generated-artifacts/IMooniswapPool.json';
import * as IMultiplexFeature from '../test/generated-artifacts/IMultiplexFeature.json';
import * as INativeOrdersEvents from '../test/generated-artifacts/INativeOrdersEvents.json';
import * as INativeOrdersFeature from '../test/generated-artifacts/INativeOrdersFeature.json';
import * as InitialMigration from '../test/generated-artifacts/InitialMigration.json';
import * as IOtcOrdersFeature from '../test/generated-artifacts/IOtcOrdersFeature.json';
import * as IOwnableFeature from '../test/generated-artifacts/IOwnableFeature.json';
import * as IPancakeSwapFeature from '../test/generated-artifacts/IPancakeSwapFeature.json';
import * as IPropertyValidator from '../test/generated-artifacts/IPropertyValidator.json';
import * as ISimpleFunctionRegistryFeature from '../test/generated-artifacts/ISimpleFunctionRegistryFeature.json';
import * as IStaking from '../test/generated-artifacts/IStaking.json';
import * as ITakerCallback from '../test/generated-artifacts/ITakerCallback.json';
import * as ITestSimpleFunctionRegistryFeature from '../test/generated-artifacts/ITestSimpleFunctionRegistryFeature.json';
import * as ITokenSpenderFeature from '../test/generated-artifacts/ITokenSpenderFeature.json';
import * as ITransformERC20Feature from '../test/generated-artifacts/ITransformERC20Feature.json';
import * as IUniswapFeature from '../test/generated-artifacts/IUniswapFeature.json';
import * as IUniswapV2Pair from '../test/generated-artifacts/IUniswapV2Pair.json';
import * as IUniswapV3Feature from '../test/generated-artifacts/IUniswapV3Feature.json';
import * as IUniswapV3Pool from '../test/generated-artifacts/IUniswapV3Pool.json';
import * as IZeroEx from '../test/generated-artifacts/IZeroEx.json';
import * as LibBootstrap from '../test/generated-artifacts/LibBootstrap.json';
import * as LibCommonRichErrors from '../test/generated-artifacts/LibCommonRichErrors.json';
import * as LibERC1155OrdersStorage from '../test/generated-artifacts/LibERC1155OrdersStorage.json';
import * as LibERC20Transformer from '../test/generated-artifacts/LibERC20Transformer.json';
import * as LibERC721OrdersStorage from '../test/generated-artifacts/LibERC721OrdersStorage.json';
import * as LibFeeCollector from '../test/generated-artifacts/LibFeeCollector.json';
import * as LibLiquidityProviderRichErrors from '../test/generated-artifacts/LibLiquidityProviderRichErrors.json';
import * as LibMetaTransactionsRichErrors from '../test/generated-artifacts/LibMetaTransactionsRichErrors.json';
import * as LibMetaTransactionsStorage from '../test/generated-artifacts/LibMetaTransactionsStorage.json';
import * as LibMigrate from '../test/generated-artifacts/LibMigrate.json';
import * as LibNativeOrder from '../test/generated-artifacts/LibNativeOrder.json';
import * as LibNativeOrdersRichErrors from '../test/generated-artifacts/LibNativeOrdersRichErrors.json';
import * as LibNativeOrdersStorage from '../test/generated-artifacts/LibNativeOrdersStorage.json';
import * as LibNFTOrder from '../test/generated-artifacts/LibNFTOrder.json';
import * as LibNFTOrdersRichErrors from '../test/generated-artifacts/LibNFTOrdersRichErrors.json';
import * as LibOtcOrdersStorage from '../test/generated-artifacts/LibOtcOrdersStorage.json';
import * as LibOwnableRichErrors from '../test/generated-artifacts/LibOwnableRichErrors.json';
import * as LibOwnableStorage from '../test/generated-artifacts/LibOwnableStorage.json';
import * as LibProxyRichErrors from '../test/generated-artifacts/LibProxyRichErrors.json';
import * as LibProxyStorage from '../test/generated-artifacts/LibProxyStorage.json';
import * as LibReentrancyGuardStorage from '../test/generated-artifacts/LibReentrancyGuardStorage.json';
import * as LibSignature from '../test/generated-artifacts/LibSignature.json';
import * as LibSignatureRichErrors from '../test/generated-artifacts/LibSignatureRichErrors.json';
import * as LibSimpleFunctionRegistryRichErrors from '../test/generated-artifacts/LibSimpleFunctionRegistryRichErrors.json';
import * as LibSimpleFunctionRegistryStorage from '../test/generated-artifacts/LibSimpleFunctionRegistryStorage.json';
import * as LibStorage from '../test/generated-artifacts/LibStorage.json';
import * as LibTransformERC20RichErrors from '../test/generated-artifacts/LibTransformERC20RichErrors.json';
import * as LibTransformERC20Storage from '../test/generated-artifacts/LibTransformERC20Storage.json';
import * as LibWalletRichErrors from '../test/generated-artifacts/LibWalletRichErrors.json';
import * as LiquidityProviderFeature from '../test/generated-artifacts/LiquidityProviderFeature.json';
import * as LiquidityProviderSandbox from '../test/generated-artifacts/LiquidityProviderSandbox.json';
import * as LogMetadataTransformer from '../test/generated-artifacts/LogMetadataTransformer.json';
import * as MetaTransactionsFeature from '../test/generated-artifacts/MetaTransactionsFeature.json';
import * as MetaTransactionsFeatureV2 from '../test/generated-artifacts/MetaTransactionsFeatureV2.json';
import * as MixinAaveV2 from '../test/generated-artifacts/MixinAaveV2.json';
import * as MixinBalancer from '../test/generated-artifacts/MixinBalancer.json';
import * as MixinBalancerV2Batch from '../test/generated-artifacts/MixinBalancerV2Batch.json';
import * as MixinBancorV3 from '../test/generated-artifacts/MixinBancorV3.json';
import * as MixinCompound from '../test/generated-artifacts/MixinCompound.json';
import * as MixinCryptoCom from '../test/generated-artifacts/MixinCryptoCom.json';
import * as MixinCurve from '../test/generated-artifacts/MixinCurve.json';
import * as MixinCurveV2 from '../test/generated-artifacts/MixinCurveV2.json';
import * as MixinDodo from '../test/generated-artifacts/MixinDodo.json';
import * as MixinDodoV2 from '../test/generated-artifacts/MixinDodoV2.json';
import * as MixinGMX from '../test/generated-artifacts/MixinGMX.json';
import * as MixinKyberDmm from '../test/generated-artifacts/MixinKyberDmm.json';
import * as MixinLido from '../test/generated-artifacts/MixinLido.json';
import * as MixinMakerPSM from '../test/generated-artifacts/MixinMakerPSM.json';
import * as MixinMooniswap from '../test/generated-artifacts/MixinMooniswap.json';
import * as MixinNerve from '../test/generated-artifacts/MixinNerve.json';
import * as MixinPlatypus from '../test/generated-artifacts/MixinPlatypus.json';
import * as MixinSolidly from '../test/generated-artifacts/MixinSolidly.json';
import * as MixinSynthetix from '../test/generated-artifacts/MixinSynthetix.json';
import * as MixinUniswap from '../test/generated-artifacts/MixinUniswap.json';
import * as MixinUniswapV2 from '../test/generated-artifacts/MixinUniswapV2.json';
import * as MixinUniswapV3 from '../test/generated-artifacts/MixinUniswapV3.json';
import * as MixinZeroExBridge from '../test/generated-artifacts/MixinZeroExBridge.json';
import * as MooniswapLiquidityProvider from '../test/generated-artifacts/MooniswapLiquidityProvider.json';
import * as MultiplexFeature from '../test/generated-artifacts/MultiplexFeature.json';
import * as MultiplexLiquidityProvider from '../test/generated-artifacts/MultiplexLiquidityProvider.json';
import * as MultiplexOtc from '../test/generated-artifacts/MultiplexOtc.json';
import * as MultiplexRfq from '../test/generated-artifacts/MultiplexRfq.json';
import * as MultiplexTransformERC20 from '../test/generated-artifacts/MultiplexTransformERC20.json';
import * as MultiplexUniswapV2 from '../test/generated-artifacts/MultiplexUniswapV2.json';
import * as MultiplexUniswapV3 from '../test/generated-artifacts/MultiplexUniswapV3.json';
import * as NativeOrdersCancellation from '../test/generated-artifacts/NativeOrdersCancellation.json';
import * as NativeOrdersFeature from '../test/generated-artifacts/NativeOrdersFeature.json';
import * as NativeOrdersInfo from '../test/generated-artifacts/NativeOrdersInfo.json';
import * as NativeOrdersProtocolFees from '../test/generated-artifacts/NativeOrdersProtocolFees.json';
import * as NativeOrdersSettlement from '../test/generated-artifacts/NativeOrdersSettlement.json';
import * as NFTOrders from '../test/generated-artifacts/NFTOrders.json';
import * as OptimismBridgeAdapter from '../test/generated-artifacts/OptimismBridgeAdapter.json';
import * as OtcOrdersFeature from '../test/generated-artifacts/OtcOrdersFeature.json';
import * as OwnableFeature from '../test/generated-artifacts/OwnableFeature.json';
import * as PancakeSwapFeature from '../test/generated-artifacts/PancakeSwapFeature.json';
import * as PayTakerTransformer from '../test/generated-artifacts/PayTakerTransformer.json';
import * as PermissionlessTransformerDeployer from '../test/generated-artifacts/PermissionlessTransformerDeployer.json';
import * as PolygonBridgeAdapter from '../test/generated-artifacts/PolygonBridgeAdapter.json';
import * as PositiveSlippageFeeTransformer from '../test/generated-artifacts/PositiveSlippageFeeTransformer.json';
import * as SimpleFunctionRegistryFeature from '../test/generated-artifacts/SimpleFunctionRegistryFeature.json';
import * as TestCurve from '../test/generated-artifacts/TestCurve.json';
import * as TestDelegateCaller from '../test/generated-artifacts/TestDelegateCaller.json';
import * as TestFeeCollectorController from '../test/generated-artifacts/TestFeeCollectorController.json';
import * as TestFeeRecipient from '../test/generated-artifacts/TestFeeRecipient.json';
import * as TestFillQuoteTransformerBridge from '../test/generated-artifacts/TestFillQuoteTransformerBridge.json';
import * as TestFillQuoteTransformerExchange from '../test/generated-artifacts/TestFillQuoteTransformerExchange.json';
import * as TestFillQuoteTransformerHost from '../test/generated-artifacts/TestFillQuoteTransformerHost.json';
import * as TestFixinProtocolFees from '../test/generated-artifacts/TestFixinProtocolFees.json';
import * as TestFixinTokenSpender from '../test/generated-artifacts/TestFixinTokenSpender.json';
import * as TestFullMigration from '../test/generated-artifacts/TestFullMigration.json';
import * as TestInitialMigration from '../test/generated-artifacts/TestInitialMigration.json';
import * as TestLibNativeOrder from '../test/generated-artifacts/TestLibNativeOrder.json';
import * as TestLibSignature from '../test/generated-artifacts/TestLibSignature.json';
import * as TestLiquidityProvider from '../test/generated-artifacts/TestLiquidityProvider.json';
import * as TestMetaTransactionsNativeOrdersFeature from '../test/generated-artifacts/TestMetaTransactionsNativeOrdersFeature.json';
import * as TestMetaTransactionsTransformERC20Feature from '../test/generated-artifacts/TestMetaTransactionsTransformERC20Feature.json';
import * as TestMigrator from '../test/generated-artifacts/TestMigrator.json';
import * as TestMintableERC1155Token from '../test/generated-artifacts/TestMintableERC1155Token.json';
import * as TestMintableERC20Token from '../test/generated-artifacts/TestMintableERC20Token.json';
import * as TestMintableERC721Token from '../test/generated-artifacts/TestMintableERC721Token.json';
import * as TestMintTokenERC20Transformer from '../test/generated-artifacts/TestMintTokenERC20Transformer.json';
import * as TestMooniswap from '../test/generated-artifacts/TestMooniswap.json';
import * as TestNativeOrdersFeature from '../test/generated-artifacts/TestNativeOrdersFeature.json';
import * as TestNFTOrderPresigner from '../test/generated-artifacts/TestNFTOrderPresigner.json';
import * as TestNoEthRecipient from '../test/generated-artifacts/TestNoEthRecipient.json';
import * as TestOrderSignerRegistryWithContractWallet from '../test/generated-artifacts/TestOrderSignerRegistryWithContractWallet.json';
import * as TestPermissionlessTransformerDeployerSuicidal from '../test/generated-artifacts/TestPermissionlessTransformerDeployerSuicidal.json';
import * as TestPermissionlessTransformerDeployerTransformer from '../test/generated-artifacts/TestPermissionlessTransformerDeployerTransformer.json';
import * as TestPropertyValidator from '../test/generated-artifacts/TestPropertyValidator.json';
import * as TestRfqOriginRegistration from '../test/generated-artifacts/TestRfqOriginRegistration.json';
import * as TestSimpleFunctionRegistryFeatureImpl1 from '../test/generated-artifacts/TestSimpleFunctionRegistryFeatureImpl1.json';
import * as TestSimpleFunctionRegistryFeatureImpl2 from '../test/generated-artifacts/TestSimpleFunctionRegistryFeatureImpl2.json';
import * as TestStaking from '../test/generated-artifacts/TestStaking.json';
import * as TestTokenSpenderERC20Token from '../test/generated-artifacts/TestTokenSpenderERC20Token.json';
import * as TestTransformerBase from '../test/generated-artifacts/TestTransformerBase.json';
import * as TestTransformERC20 from '../test/generated-artifacts/TestTransformERC20.json';
import * as TestTransformerDeployerTransformer from '../test/generated-artifacts/TestTransformerDeployerTransformer.json';
import * as TestTransformerHost from '../test/generated-artifacts/TestTransformerHost.json';
import * as TestUniswapV2Factory from '../test/generated-artifacts/TestUniswapV2Factory.json';
import * as TestUniswapV2Pool from '../test/generated-artifacts/TestUniswapV2Pool.json';
import * as TestUniswapV3Factory from '../test/generated-artifacts/TestUniswapV3Factory.json';
import * as TestUniswapV3Feature from '../test/generated-artifacts/TestUniswapV3Feature.json';
import * as TestUniswapV3Pool from '../test/generated-artifacts/TestUniswapV3Pool.json';
import * as TestWeth from '../test/generated-artifacts/TestWeth.json';
import * as TestWethTransformerHost from '../test/generated-artifacts/TestWethTransformerHost.json';
import * as Transformer from '../test/generated-artifacts/Transformer.json';
import * as TransformERC20Feature from '../test/generated-artifacts/TransformERC20Feature.json';
import * as TransformerDeployer from '../test/generated-artifacts/TransformerDeployer.json';
import * as UniswapFeature from '../test/generated-artifacts/UniswapFeature.json';
import * as UniswapV3Feature from '../test/generated-artifacts/UniswapV3Feature.json';
import * as WethTransformer from '../test/generated-artifacts/WethTransformer.json';
import * as ZeroEx from '../test/generated-artifacts/ZeroEx.json';
import * as ZeroExOptimized from '../test/generated-artifacts/ZeroExOptimized.json';
export const artifacts = {
    IZeroEx: IZeroEx as ContractArtifact,
    ZeroEx: ZeroEx as ContractArtifact,
    ZeroExOptimized: ZeroExOptimized as ContractArtifact,
    LibCommonRichErrors: LibCommonRichErrors as ContractArtifact,
    LibLiquidityProviderRichErrors: LibLiquidityProviderRichErrors as ContractArtifact,
    LibMetaTransactionsRichErrors: LibMetaTransactionsRichErrors as ContractArtifact,
    LibNFTOrdersRichErrors: LibNFTOrdersRichErrors as ContractArtifact,
    LibNativeOrdersRichErrors: LibNativeOrdersRichErrors as ContractArtifact,
    LibOwnableRichErrors: LibOwnableRichErrors as ContractArtifact,
    LibProxyRichErrors: LibProxyRichErrors as ContractArtifact,
    LibSignatureRichErrors: LibSignatureRichErrors as ContractArtifact,
    LibSimpleFunctionRegistryRichErrors: LibSimpleFunctionRegistryRichErrors as ContractArtifact,
    LibTransformERC20RichErrors: LibTransformERC20RichErrors as ContractArtifact,
    LibWalletRichErrors: LibWalletRichErrors as ContractArtifact,
    BatchMultiplexValidator: BatchMultiplexValidator as ContractArtifact,
    FeeCollector: FeeCollector as ContractArtifact,
    FeeCollectorController: FeeCollectorController as ContractArtifact,
    FlashWallet: FlashWallet as ContractArtifact,
    IFlashWallet: IFlashWallet as ContractArtifact,
    ILiquidityProviderSandbox: ILiquidityProviderSandbox as ContractArtifact,
    LibFeeCollector: LibFeeCollector as ContractArtifact,
    LiquidityProviderSandbox: LiquidityProviderSandbox as ContractArtifact,
    PermissionlessTransformerDeployer: PermissionlessTransformerDeployer as ContractArtifact,
    TransformerDeployer: TransformerDeployer as ContractArtifact,
    BatchFillNativeOrdersFeature: BatchFillNativeOrdersFeature as ContractArtifact,
    BootstrapFeature: BootstrapFeature as ContractArtifact,
    ERC165Feature: ERC165Feature as ContractArtifact,
    FundRecoveryFeature: FundRecoveryFeature as ContractArtifact,
    LiquidityProviderFeature: LiquidityProviderFeature as ContractArtifact,
    MetaTransactionsFeature: MetaTransactionsFeature as ContractArtifact,
    MetaTransactionsFeatureV2: MetaTransactionsFeatureV2 as ContractArtifact,
    NativeOrdersFeature: NativeOrdersFeature as ContractArtifact,
    OtcOrdersFeature: OtcOrdersFeature as ContractArtifact,
    OwnableFeature: OwnableFeature as ContractArtifact,
    PancakeSwapFeature: PancakeSwapFeature as ContractArtifact,
    SimpleFunctionRegistryFeature: SimpleFunctionRegistryFeature as ContractArtifact,
    TransformERC20Feature: TransformERC20Feature as ContractArtifact,
    UniswapFeature: UniswapFeature as ContractArtifact,
    UniswapV3Feature: UniswapV3Feature as ContractArtifact,
    IBatchFillNativeOrdersFeature: IBatchFillNativeOrdersFeature as ContractArtifact,
    IBatchMultiplexFeature: IBatchMultiplexFeature as ContractArtifact,
    IBootstrapFeature: IBootstrapFeature as ContractArtifact,
    IERC1155OrdersFeature: IERC1155OrdersFeature as ContractArtifact,
    IERC165Feature: IERC165Feature as ContractArtifact,
    IERC721OrdersFeature: IERC721OrdersFeature as ContractArtifact,
    IFeature: IFeature as ContractArtifact,
    IFundRecoveryFeature: IFundRecoveryFeature as ContractArtifact,
    ILiquidityProviderFeature: ILiquidityProviderFeature as ContractArtifact,
    IMetaTransactionsFeature: IMetaTransactionsFeature as ContractArtifact,
    IMetaTransactionsFeatureV2: IMetaTransactionsFeatureV2 as ContractArtifact,
    IMultiplexFeature: IMultiplexFeature as ContractArtifact,
    INativeOrdersEvents: INativeOrdersEvents as ContractArtifact,
    INativeOrdersFeature: INativeOrdersFeature as ContractArtifact,
    IOtcOrdersFeature: IOtcOrdersFeature as ContractArtifact,
    IOwnableFeature: IOwnableFeature as ContractArtifact,
    IPancakeSwapFeature: IPancakeSwapFeature as ContractArtifact,
    ISimpleFunctionRegistryFeature: ISimpleFunctionRegistryFeature as ContractArtifact,
    ITokenSpenderFeature: ITokenSpenderFeature as ContractArtifact,
    ITransformERC20Feature: ITransformERC20Feature as ContractArtifact,
    IUniswapFeature: IUniswapFeature as ContractArtifact,
    IUniswapV3Feature: IUniswapV3Feature as ContractArtifact,
    LibNFTOrder: LibNFTOrder as ContractArtifact,
    LibNativeOrder: LibNativeOrder as ContractArtifact,
    LibSignature: LibSignature as ContractArtifact,
    BatchMultiplexFeature: BatchMultiplexFeature as ContractArtifact,
    MultiplexFeature: MultiplexFeature as ContractArtifact,
    MultiplexLiquidityProvider: MultiplexLiquidityProvider as ContractArtifact,
    MultiplexOtc: MultiplexOtc as ContractArtifact,
    MultiplexRfq: MultiplexRfq as ContractArtifact,
    MultiplexTransformERC20: MultiplexTransformERC20 as ContractArtifact,
    MultiplexUniswapV2: MultiplexUniswapV2 as ContractArtifact,
    MultiplexUniswapV3: MultiplexUniswapV3 as ContractArtifact,
    NativeOrdersCancellation: NativeOrdersCancellation as ContractArtifact,
    NativeOrdersInfo: NativeOrdersInfo as ContractArtifact,
    NativeOrdersProtocolFees: NativeOrdersProtocolFees as ContractArtifact,
    NativeOrdersSettlement: NativeOrdersSettlement as ContractArtifact,
    ERC1155OrdersFeature: ERC1155OrdersFeature as ContractArtifact,
    ERC721OrdersFeature: ERC721OrdersFeature as ContractArtifact,
    NFTOrders: NFTOrders as ContractArtifact,
    FixinCommon: FixinCommon as ContractArtifact,
    FixinEIP712: FixinEIP712 as ContractArtifact,
    FixinERC1155Spender: FixinERC1155Spender as ContractArtifact,
    FixinERC721Spender: FixinERC721Spender as ContractArtifact,
    FixinProtocolFees: FixinProtocolFees as ContractArtifact,
    FixinReentrancyGuard: FixinReentrancyGuard as ContractArtifact,
    FixinTokenSpender: FixinTokenSpender as ContractArtifact,
    CurveLiquidityProvider: CurveLiquidityProvider as ContractArtifact,
    MooniswapLiquidityProvider: MooniswapLiquidityProvider as ContractArtifact,
    FullMigration: FullMigration as ContractArtifact,
    InitialMigration: InitialMigration as ContractArtifact,
    LibBootstrap: LibBootstrap as ContractArtifact,
    LibMigrate: LibMigrate as ContractArtifact,
    LibERC1155OrdersStorage: LibERC1155OrdersStorage as ContractArtifact,
    LibERC721OrdersStorage: LibERC721OrdersStorage as ContractArtifact,
    LibMetaTransactionsStorage: LibMetaTransactionsStorage as ContractArtifact,
    LibNativeOrdersStorage: LibNativeOrdersStorage as ContractArtifact,
    LibOtcOrdersStorage: LibOtcOrdersStorage as ContractArtifact,
    LibOwnableStorage: LibOwnableStorage as ContractArtifact,
    LibProxyStorage: LibProxyStorage as ContractArtifact,
    LibReentrancyGuardStorage: LibReentrancyGuardStorage as ContractArtifact,
    LibSimpleFunctionRegistryStorage: LibSimpleFunctionRegistryStorage as ContractArtifact,
    LibStorage: LibStorage as ContractArtifact,
    LibTransformERC20Storage: LibTransformERC20Storage as ContractArtifact,
    AffiliateFeeTransformer: AffiliateFeeTransformer as ContractArtifact,
    FillQuoteTransformer: FillQuoteTransformer as ContractArtifact,
    IERC20Transformer: IERC20Transformer as ContractArtifact,
    LibERC20Transformer: LibERC20Transformer as ContractArtifact,
    LogMetadataTransformer: LogMetadataTransformer as ContractArtifact,
    PayTakerTransformer: PayTakerTransformer as ContractArtifact,
    PositiveSlippageFeeTransformer: PositiveSlippageFeeTransformer as ContractArtifact,
    Transformer: Transformer as ContractArtifact,
    WethTransformer: WethTransformer as ContractArtifact,
    AbstractBridgeAdapter: AbstractBridgeAdapter as ContractArtifact,
    ArbitrumBridgeAdapter: ArbitrumBridgeAdapter as ContractArtifact,
    AvalancheBridgeAdapter: AvalancheBridgeAdapter as ContractArtifact,
    BSCBridgeAdapter: BSCBridgeAdapter as ContractArtifact,
    BaseBridgeAdapter: BaseBridgeAdapter as ContractArtifact,
    BaseGoerliBridgeAdapter: BaseGoerliBridgeAdapter as ContractArtifact,
    BridgeProtocols: BridgeProtocols as ContractArtifact,
    CeloBridgeAdapter: CeloBridgeAdapter as ContractArtifact,
    EthereumBridgeAdapter: EthereumBridgeAdapter as ContractArtifact,
    FantomBridgeAdapter: FantomBridgeAdapter as ContractArtifact,
    IBridgeAdapter: IBridgeAdapter as ContractArtifact,
    OptimismBridgeAdapter: OptimismBridgeAdapter as ContractArtifact,
    PolygonBridgeAdapter: PolygonBridgeAdapter as ContractArtifact,
    MixinAaveV2: MixinAaveV2 as ContractArtifact,
    MixinBalancer: MixinBalancer as ContractArtifact,
    MixinBalancerV2Batch: MixinBalancerV2Batch as ContractArtifact,
    MixinBancorV3: MixinBancorV3 as ContractArtifact,
    MixinCompound: MixinCompound as ContractArtifact,
    MixinCryptoCom: MixinCryptoCom as ContractArtifact,
    MixinCurve: MixinCurve as ContractArtifact,
    MixinCurveV2: MixinCurveV2 as ContractArtifact,
    MixinDodo: MixinDodo as ContractArtifact,
    MixinDodoV2: MixinDodoV2 as ContractArtifact,
    MixinGMX: MixinGMX as ContractArtifact,
    MixinKyberDmm: MixinKyberDmm as ContractArtifact,
    MixinLido: MixinLido as ContractArtifact,
    MixinMakerPSM: MixinMakerPSM as ContractArtifact,
    MixinMooniswap: MixinMooniswap as ContractArtifact,
    MixinNerve: MixinNerve as ContractArtifact,
    MixinPlatypus: MixinPlatypus as ContractArtifact,
    MixinSolidly: MixinSolidly as ContractArtifact,
    MixinSynthetix: MixinSynthetix as ContractArtifact,
    MixinUniswap: MixinUniswap as ContractArtifact,
    MixinUniswapV2: MixinUniswapV2 as ContractArtifact,
    MixinUniswapV3: MixinUniswapV3 as ContractArtifact,
    MixinZeroExBridge: MixinZeroExBridge as ContractArtifact,
    IERC1155Token: IERC1155Token as ContractArtifact,
    IERC721Token: IERC721Token as ContractArtifact,
    IFeeRecipient: IFeeRecipient as ContractArtifact,
    ILiquidityProvider: ILiquidityProvider as ContractArtifact,
    IMooniswapPool: IMooniswapPool as ContractArtifact,
    IPropertyValidator: IPropertyValidator as ContractArtifact,
    ITakerCallback: ITakerCallback as ContractArtifact,
    IUniswapV2Pair: IUniswapV2Pair as ContractArtifact,
    IUniswapV3Pool: IUniswapV3Pool as ContractArtifact,
    IERC20Bridge: IERC20Bridge as ContractArtifact,
    IStaking: IStaking as ContractArtifact,
    ITestSimpleFunctionRegistryFeature: ITestSimpleFunctionRegistryFeature as ContractArtifact,
    TestDelegateCaller: TestDelegateCaller as ContractArtifact,
    TestFeeCollectorController: TestFeeCollectorController as ContractArtifact,
    TestFeeRecipient: TestFeeRecipient as ContractArtifact,
    TestFillQuoteTransformerBridge: TestFillQuoteTransformerBridge as ContractArtifact,
    TestFillQuoteTransformerExchange: TestFillQuoteTransformerExchange as ContractArtifact,
    TestFillQuoteTransformerHost: TestFillQuoteTransformerHost as ContractArtifact,
    TestFixinProtocolFees: TestFixinProtocolFees as ContractArtifact,
    TestFixinTokenSpender: TestFixinTokenSpender as ContractArtifact,
    TestFullMigration: TestFullMigration as ContractArtifact,
    TestInitialMigration: TestInitialMigration as ContractArtifact,
    TestLibNativeOrder: TestLibNativeOrder as ContractArtifact,
    TestLibSignature: TestLibSignature as ContractArtifact,
    TestMetaTransactionsNativeOrdersFeature: TestMetaTransactionsNativeOrdersFeature as ContractArtifact,
    TestMetaTransactionsTransformERC20Feature: TestMetaTransactionsTransformERC20Feature as ContractArtifact,
    TestMigrator: TestMigrator as ContractArtifact,
    TestMintTokenERC20Transformer: TestMintTokenERC20Transformer as ContractArtifact,
    TestNFTOrderPresigner: TestNFTOrderPresigner as ContractArtifact,
    TestNativeOrdersFeature: TestNativeOrdersFeature as ContractArtifact,
    TestNoEthRecipient: TestNoEthRecipient as ContractArtifact,
    TestOrderSignerRegistryWithContractWallet: TestOrderSignerRegistryWithContractWallet as ContractArtifact,
    TestPermissionlessTransformerDeployerSuicidal: TestPermissionlessTransformerDeployerSuicidal as ContractArtifact,
    TestPermissionlessTransformerDeployerTransformer:
        TestPermissionlessTransformerDeployerTransformer as ContractArtifact,
    TestPropertyValidator: TestPropertyValidator as ContractArtifact,
    TestRfqOriginRegistration: TestRfqOriginRegistration as ContractArtifact,
    TestSimpleFunctionRegistryFeatureImpl1: TestSimpleFunctionRegistryFeatureImpl1 as ContractArtifact,
    TestSimpleFunctionRegistryFeatureImpl2: TestSimpleFunctionRegistryFeatureImpl2 as ContractArtifact,
    TestStaking: TestStaking as ContractArtifact,
    TestTransformERC20: TestTransformERC20 as ContractArtifact,
    TestTransformerBase: TestTransformerBase as ContractArtifact,
    TestTransformerDeployerTransformer: TestTransformerDeployerTransformer as ContractArtifact,
    TestTransformerHost: TestTransformerHost as ContractArtifact,
    TestUniswapV3Feature: TestUniswapV3Feature as ContractArtifact,
    TestWethTransformerHost: TestWethTransformerHost as ContractArtifact,
    TestCurve: TestCurve as ContractArtifact,
    TestLiquidityProvider: TestLiquidityProvider as ContractArtifact,
    TestMooniswap: TestMooniswap as ContractArtifact,
    TestUniswapV2Factory: TestUniswapV2Factory as ContractArtifact,
    TestUniswapV2Pool: TestUniswapV2Pool as ContractArtifact,
    TestUniswapV3Factory: TestUniswapV3Factory as ContractArtifact,
    TestUniswapV3Pool: TestUniswapV3Pool as ContractArtifact,
    TestMintableERC1155Token: TestMintableERC1155Token as ContractArtifact,
    TestMintableERC20Token: TestMintableERC20Token as ContractArtifact,
    TestMintableERC721Token: TestMintableERC721Token as ContractArtifact,
    TestTokenSpenderERC20Token: TestTokenSpenderERC20Token as ContractArtifact,
    TestWeth: TestWeth as ContractArtifact,
};
