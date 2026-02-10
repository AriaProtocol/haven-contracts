import 'dotenv/config';

import { HardhatUserConfig, subtask, task } from 'hardhat/config';
import '@compound-finance/hardhat-import';
import '@nomiclabs/hardhat-etherscan';
import '@tenderly/hardhat-tenderly';
import '@nomiclabs/hardhat-ethers';
import '@typechain/hardhat';
import 'hardhat-chai-matchers';
import 'hardhat-change-network';
import 'hardhat-contract-sizer';
import 'solidity-coverage';
import 'hardhat-gas-reporter';
import { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from 'hardhat/builtin-tasks/task-names';
// Hardhat tasks
import './tasks/deployment_manager/task.ts';
import './tasks/spider/task.ts';
import './tasks/scenario/task.ts';

// Relation Config
import relationConfigMap from './deployments/relations';

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  for (const account of await hre.ethers.getSigners()) console.log(account.address);
});

/* note: boolean environment variables are imported as strings */
const {
  COINMARKETCAP_API_KEY,
  ETH_PK,
  ANKR_KEY,
  MNEMONIC = 'myth like woof scare over problem client lizard pioneer submit female collect',
  REPORT_GAS = 'false',
  NETWORK_PROVIDER = '',
  GOV_NETWORK_PROVIDER = '',
  GOV_NETWORK = '',
  REMOTE_ACCOUNTS = ''
} = process.env;

function* deriveAccounts(pk: string, n: number = 10) {
  for (let i = 0; i < n; i++){
    if(!pk.startsWith('0x')) pk = '0x' + pk;
    yield (BigInt(pk) + BigInt(i)).toString(16);
  }
}

export function requireEnv(varName, msg?: string): string {
  const varVal = process.env[varName];
  if (!varVal) {
    throw new Error(msg ?? `Missing required environment variable '${varName}'`);
  }
  return varVal;
}

// required environment variables
[
  'ANKR_KEY',
].map((v) => requireEnv(v));

// Networks
interface NetworkConfig {
  network: string;
  chainId: number;
  url?: string;
  gas?: number | 'auto';
  gasPrice?: number | 'auto';
}

subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(async (_, __, runSuper) => {
  const paths = await runSuper();
  
  return paths.filter((p: string) => {
    return !(
      p.includes('dependencies/woof-software-compound-capo-lst-lrt-oracles/contracts/test/') ||
      p.includes('dependencies/woof-software-compound-capo-lst-lrt-oracles/test/') ||
      p.includes('dependencies/forge-std-1.11.0/src/') ||
      p.endsWith('.t.sol')
    );
  });
});

export const networkConfigs: NetworkConfig[] = [
  {
    network: 'aeneid',
    chainId: 1315,
    url: `https://rpc.ankr.com/story_aeneid_testnet/${ANKR_KEY}`,
  },
  {
    network: 'anvil',
    chainId: 31337,
    url: `http://localhost:8545`,
  },
  {
    network: 'story',
    chainId: 1514,
    url: `https://rpc.ankr.com/story_mainnet/${ANKR_KEY}`,
  }
];

function getDefaultProviderURL(network: string) {
  return `https://rpc.ankr.com/${network}/${ANKR_KEY}`;
}

function setupDefaultNetworkProviders(hardhatConfig: HardhatUserConfig) {
  for (const netConfig of networkConfigs) {
    hardhatConfig.networks[netConfig.network] = {
      chainId: netConfig.chainId,
      url:
        (netConfig.network === GOV_NETWORK ? GOV_NETWORK_PROVIDER || undefined : undefined) ||
        NETWORK_PROVIDER ||
        netConfig.url ||
        getDefaultProviderURL(netConfig.network),
      gas: netConfig.gas || 'auto',
      gasPrice: netConfig.gasPrice || 'auto',
      accounts: REMOTE_ACCOUNTS
        ? 'remote'
        : ETH_PK
          ? [...deriveAccounts(ETH_PK)]
          : { mnemonic: MNEMONIC },
      ...hardhatConfig.networks?.[netConfig.network],
    };
  }
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.20',
    settings: {
      optimizer: process.env['OPTIMIZER_DISABLED']
        ? { enabled: false }
        : {
          enabled: true,
          runs: 1,
          details: {
            yulDetails: {
              optimizerSteps:
                  'dhfoDgvulfnTUtnIf [xa[r]scLM cCTUtTOntnfDIul Lcul Vcul [j] Tpeul xa[rul] xa[r]cL gvif CTUca[r]LsTOtfDnca[r]Iulc] jmul[jul] VcTOcul jmul',
            },
          },
        },
      outputSelection: {
        '*': {
          '*': ['evm.deployedBytecode.sourceMap'],
        },
      },
      viaIR: process.env['OPTIMIZER_DISABLED'] ? false : true,
    },
  },

  networks: {
    hardhat: {
      chainId: 1337,
      loggingEnabled: !!process.env['LOGGING'],
      gas: 120000000,
      gasPrice: 'auto',
      blockGasLimit: 120000000,
      accounts: ETH_PK
        ? [...deriveAccounts(ETH_PK)].map((privateKey) => ({
          privateKey,
          balance: (10n ** 36n).toString(),
        }))
        : { mnemonic: MNEMONIC, accountsBalance: (10n ** 36n).toString() },
      // this should only be relied upon for test harnesses and coverage (which does not use viaIR flag)
      allowUnlimitedContractSize: true,
      //hardfork: 'london',
      chains: networkConfigs.reduce((acc, { chainId }) => {
        if (chainId === 1) return acc;
        if (chainId === 59144) {
          acc[chainId] = {
            hardforkHistory: {
              berlin: 1,
              london: 2,
            },
          };
          return acc;
        }
        if (chainId === 42161) {
          acc[chainId] = {
            hardforkHistory: {
              berlin: 1,
              london: 2,
            },
          };
          return acc;
        }
        if (chainId === 5000) {
          acc[chainId] = {
            hardforkHistory: {
              berlin: 1,
              london: 2,
            },
          };
          return acc;
        }
        if (chainId === 137) {
          acc[chainId] = {
            hardforkHistory: {
              berlin: 1,
              london: 2,
            },
          };
          return acc;
        }
        if (chainId === 534352) {
          acc[chainId] = {
            hardforkHistory: {
              berlin: 1,
              london: 2,
            },
          };
          return acc;
        }
        if (chainId === 2020) {
          acc[chainId] = {
            hardforkHistory: {
              berlin: 1,
              london: 2,
            },
          };
          return acc;
        }
        if (chainId === 42161) {
          acc[chainId] = {
            hardforkHistory: {
              berlin: 1,
              london: 2,
              shanghai: 3,
            },
          };
          return acc;
        }
        acc[chainId] = {
          hardforkHistory: {
            berlin: 1,
            london: 2,
            shanghai: 3,
            cancun: 4,
          },
        };
        return acc;
      }, {}),
    },
    anvil: {
      chainId: 31337,
      accounts: {
        mnemonic: 'test test test test test test test test test test test junk', // default anvil seed
      },
    },
  },

  // See https://hardhat.org/plugins/nomiclabs-hardhat-etherscan.html#multiple-api-keys-and-alternative-block-explorers
  etherscan: {
    apiKey: {
      aeneid: 'default',
      story: 'default',
    },
    customChains: [
      {
        network: 'aeneid',
        chainId: 1315,
        urls: {
          apiURL: 'https://aeneid.storyscan.io/api/',
          browserURL: 'https://aeneid.storyscan.io/',
        },
      },
      {
        network: 'story',
        chainId: 1514,
        urls: {
          apiURL: 'https://www.storyscan.io/api/',
          browserURL: 'https://www.storyscan.io/',
        },
      },
    ],
  },

  typechain: {
    outDir: 'build/types',
    target: 'ethers-v5',
  },

  deploymentManager: {
    relationConfigMap,
    networks: {
    },
  },

  scenario: {
    bases: [
      {
        name: 'mainnet',
        network: 'mainnet',
        deployment: 'usdc',
        allocation: 1.0, // eth
      },
      {
        name: 'mainnet-weth',
        network: 'mainnet',
        deployment: 'weth',
      },
      {
        name: 'mainnet-usdt',
        network: 'mainnet',
        deployment: 'usdt',
      },
      {
        name: 'mainnet-wsteth',
        network: 'mainnet',
        deployment: 'wsteth',
      },
      {
        name: 'mainnet-usds',
        network: 'mainnet',
        deployment: 'usds',
      },
      {
        name: 'mainnet-wbtc',
        network: 'mainnet',
        deployment: 'wbtc',
      },
      {
        name: 'development',
        network: 'hardhat',
        deployment: 'dai',
      },
      {
        name: 'fuji',
        network: 'fuji',
        deployment: 'usdc',
      },
      {
        name: 'sepolia-usdc',
        network: 'sepolia',
        deployment: 'usdc',
      },
      {
        name: 'sepolia-weth',
        network: 'sepolia',
        deployment: 'weth',
      },
      {
        name: 'polygon',
        network: 'polygon',
        deployment: 'usdc',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'polygon-usdt',
        network: 'polygon',
        deployment: 'usdt',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'arbitrum-usdc.e',
        network: 'arbitrum',
        deployment: 'usdc.e',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'arbitrum-usdt',
        network: 'arbitrum',
        deployment: 'usdt',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'arbitrum-usdc',
        network: 'arbitrum',
        deployment: 'usdc',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'arbitrum-weth',
        network: 'arbitrum',
        deployment: 'weth',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'base-usdbc',
        network: 'base',
        deployment: 'usdbc',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'base-weth',
        network: 'base',
        deployment: 'weth',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'base-usdc',
        network: 'base',
        deployment: 'usdc',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'base-aero',
        network: 'base',
        deployment: 'aero',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'base-usds',
        network: 'base',
        deployment: 'usds',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'optimism-usdc',
        network: 'optimism',
        deployment: 'usdc',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'optimism-usdt',
        network: 'optimism',
        deployment: 'usdt',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'optimism-weth',
        network: 'optimism',
        deployment: 'weth',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'mantle-usde',
        network: 'mantle',
        deployment: 'usde',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'unichain-usdc',
        network: 'unichain',
        deployment: 'usdc',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'unichain-weth',
        network: 'unichain',
        deployment: 'weth',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'scroll-usdc',
        network: 'scroll',
        deployment: 'usdc',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'linea-usdc',
        network: 'linea',
        deployment: 'usdc',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'linea-weth',
        network: 'linea',
        deployment: 'weth',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'ronin-weth',
        network: 'ronin',
        deployment: 'weth',
        auxiliaryBase: 'mainnet',
      },
      {
        name: 'ronin-wron',
        network: 'ronin',
        deployment: 'wron',
        auxiliaryBase: 'mainnet',
      },
    ],
  },

  tenderly: {
    project: 'comet',
    username: process.env.TENDERLY_USERNAME || '',
    accessKey: process.env.TENDERLY_ACCESS_KEY || '',
    privateVerification: false,
  },

  mocha: {
    reporter: 'mocha-multi-reporters',
    reporterOptions: {
      reporterEnabled: ['spec', 'json'],
      jsonReporterOptions: {
        output: 'test-results.json',
      },
    },
    timeout: 150_000,
  },

  paths: {
    tests: './test/hardhat',
  },

  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: false, // allow tests to run anyway
  },

  gasReporter: {
    enabled: REPORT_GAS === 'true' ? true : false,
    currency: 'USD',
    coinmarketcap: COINMARKETCAP_API_KEY,
    gasPrice: 200, // gwei
  },
};

setupDefaultNetworkProviders(config);

export default config;
