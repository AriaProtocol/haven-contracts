import { Deployed, DeploymentManager } from '../../../plugins/deployment_manager';
import { FaucetToken, SimplePriceFeed } from '../../../build/types';
import { DeploySpec, cloneGov, deployComet, exp, sameAddress, wait } from '../../../src/deploy';

export default async function deploy(deploymentManager: DeploymentManager, deploySpec: DeploySpec): Promise<Deployed> {
  deploySpec.excludeRewards = true;

  // Deploy all Comet-related contracts
  const deployed = await deployComet(deploymentManager, deploySpec);

  return { ...deployed };
}
