import { Deployed, DeploymentManager } from '../../../plugins/deployment_manager';
import { DeploySpec, deployComet } from '../../../src/deploy';

export default async function deploy(deploymentManager: DeploymentManager, deploySpec: DeploySpec): Promise<Deployed> {
  deploySpec.excludeRewards = true;

  // import from USDC market, as it was the first deployed market
  const cometFactory = await deploymentManager.fromDep(
    "cometFactory",
    "base",
    "usdc"
  );
  const cometProxyAdmin = await deploymentManager.fromDep(
    "cometAdmin",
    "base",
    "usdc"
  );
  const configurator = await deploymentManager.fromDep(
    "configurator",
    "aeneid",
    "usdc"
  );
  const $configuratorImpl = await deploymentManager.fromDep(
    "configurator:implementation",
    "aeneid",
    "usdc"
  );

  // Deploy all Comet-related contracts
  const deployed = await deployComet(deploymentManager, deploySpec);

  return { ...deployed };
}
