import {
  Deployed,
  DeploymentManager,
} from "../../../plugins/deployment_manager";
import { FaucetToken, SimplePriceFeed } from "../../../build/types";
import {
  DeploySpec
} from "../../../src/deploy";

async function makeToken(
  deploymentManager: DeploymentManager,
  amount: number,
  name: string,
  decimals: number,
  symbol: string
): Promise<FaucetToken> {
  const mint = (BigInt(amount) * 10n ** BigInt(decimals)).toString();
  return deploymentManager.deploy(symbol, "test/FaucetToken.sol", [
    mint,
    name,
    decimals,
    symbol,
  ]);
}

async function makePriceFeed(
  deploymentManager: DeploymentManager,
  alias: string,
  initialPrice: number,
  decimals: number
): Promise<SimplePriceFeed> {
  return deploymentManager.deploy(alias, "test/SimplePriceFeed.sol", [
    initialPrice * 1e8,
    decimals,
  ]);
}

export default async function deploy(
  deploymentManager: DeploymentManager,
  deploySpec: DeploySpec
): Promise<Deployed> {
  const trace = deploymentManager.tracer();
  const ethers = deploymentManager.hre.ethers;
  const signer = await deploymentManager.getSigner();

  const IP = await makeToken(
    deploymentManager,
    10_000,
    "IP native",
    18,
    "IP"
  );

  const IPFeed = await makePriceFeed(
    deploymentManager,
    "IP native:priceFeed",
    2.35,
    8
  );

  return { IP , IPFeed };
}
