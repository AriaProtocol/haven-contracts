import { Deployed, DeploymentManager } from '../../../plugins/deployment_manager';
import { DeploySpec, deployComet } from '../../../src/deploy';

export default async function deploy(deploymentManager: DeploymentManager, deploySpec: DeploySpec): Promise<Deployed> {
  // Ensure we don't force redeploy everything, which would overwrite imports
  // This ensures that imported contracts (factories, admin, configurator) are reused
  deploySpec.all = false;
  deploySpec.excludeRewards = true;

  // import from USDC market, as it was the first deployed market
  const cometFactory = await deploymentManager.fromDep(
    "cometFactory",
    "aeneid",
    "ip"
  );
  const cometProxyAdmin = await deploymentManager.fromDep(
    "cometAdmin",
    "aeneid",
    "ip"
  );
  const configurator = await deploymentManager.fromDep(
    "configurator",
    "aeneid",
    "ip"
  );
  const $configuratorImpl = await deploymentManager.fromDep(
    "configurator:implementation",
    "aeneid",
    "ip"
  );

  // Deploy all Comet-related contracts
  const deployed = await deployComet(deploymentManager, deploySpec);

  return { ...deployed };
}
