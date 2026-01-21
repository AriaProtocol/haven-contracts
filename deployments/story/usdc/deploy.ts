import { Deployed, DeploymentManager } from '../../../plugins/deployment_manager';
import { DeploySpec, deployComet } from '../../../src/deploy';

export default async function deploy(deploymentManager: DeploymentManager, deploySpec: DeploySpec): Promise<Deployed> {
  deploySpec.excludeRewards = true;

  // Deploy all Comet-related contracts
  const deployed = await deployComet(deploymentManager, deploySpec);

  return { ...deployed };
}
