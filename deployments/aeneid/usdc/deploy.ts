import { Deployed, DeploymentManager } from '../../../plugins/deployment_manager';
import { FaucetToken, SimplePriceFeed } from '../../../build/types';
import { DeploySpec, cloneGov, deployComet, exp, sameAddress, wait } from '../../../src/deploy';

async function makeToken(
  deploymentManager: DeploymentManager,
  amount: number,
  name: string,
  decimals: number,
  symbol: string
): Promise<FaucetToken> {
  const mint = (BigInt(amount) * 10n ** BigInt(decimals)).toString();
  return deploymentManager.deploy(symbol, 'test/FaucetToken.sol', [mint, name, decimals, symbol]);
}

async function makePriceFeed(
  deploymentManager: DeploymentManager,
  alias: string,
  initialPrice: number,
  decimals: number
): Promise<SimplePriceFeed> {
  return deploymentManager.deploy(alias, 'test/SimplePriceFeed.sol', [initialPrice * 1e8, decimals]);
}

// TODO: Support configurable assets as well?
export default async function deploy(deploymentManager: DeploymentManager, deploySpec: DeploySpec): Promise<Deployed> {
  const trace = deploymentManager.tracer();
  const ethers = deploymentManager.hre.ethers;
  const signer = await deploymentManager.getSigner();

  const USDC = await makeToken(deploymentManager, 10_000_000, 'USDC', 6, 'USDC');
  const WBTC = await makeToken(deploymentManager, 350, 'WBTC', 8, 'WBTC');
  const WETH = await makeToken(deploymentManager, 800, 'WETH', 18, 'WETH');
  const USDCdecimals = await USDC.decimals();
  const WBTCdecimals = await WBTC.decimals();
  const WETHdecimals = await WETH.decimals();

  const USDCPriceFeed = await makePriceFeed(deploymentManager, 'USDC:priceFeed', 1, 8);
  const WBTCPriceFeed = await makePriceFeed(deploymentManager, 'WBTC:priceFeed', 90_000, 8);
  const WETHPriceFeed = await makePriceFeed(deploymentManager, 'WETH:priceFeed', 3_000, 8);

  const assetConfig0 = {
    asset: WBTC.address,
    priceFeed: WBTCPriceFeed.address,
    decimals: WBTCdecimals.toString(),
    borrowCollateralFactor: (0.7e18).toString(),
    liquidateCollateralFactor: (0.77e18).toString(),
    liquidationFactor: (0.95e18).toString(),
    supplyCap: (500 * 10 ** WBTCdecimals).toString(),
  };

  const assetConfig1 = {
    asset: WETH.address,
    priceFeed: WETHPriceFeed.address,
    decimals: WETHdecimals.toString(),
    borrowCollateralFactor: (0.8e18).toString(),
    liquidateCollateralFactor: (0.9e18).toString(),
    liquidationFactor: (0.95e18).toString(),
    supplyCap: (BigInt(16_700) * 10n ** BigInt(WETHdecimals)).toString(),
  };

  // Deploy all Comet-related contracts
  const deployed = await deployComet(deploymentManager, deploySpec, {
    baseTokenPriceFeed: USDCPriceFeed.address,
    assetConfigs: [assetConfig0, assetConfig1],
  });

  return { ...deployed };
}
