import axios from 'axios';
import 'dotenv/config';

export interface Result {
  status: string;
  message: string;
  result: string;
}

export function getBlockscoutApiUrl(network: string): string {
  let host = {
    'unichain': 'unichain.blockscout.com',
    'aeneid': 'aeneid.storyscan.io',
    'story': 'storyscan.io',
  }[network];

  if (!host) {
    throw new Error(`Unknown blockscout API host for network ${network}`);
  }

  return `https://${host}/api`;
}

export function getBlockscoutUrl(network: string): string {
  let host = {
    'unichain': 'unichain.blockscout.com',
    'aeneid': 'aeneid.storyscan.io',
    'story': 'storyscan.io',
  }[network];

  if (!host) {
    throw new Error(`Unknown blockscout host for network ${network}`);
  }

  return `https://${host}`;
}

export async function getBlockscoutRPCUrl(network: string): Promise<string> {
  let host = {
    unichain: `multi-boldest-patina.unichain-mainnet.quiknode.pro/${process.env.UNICHAIN_QUICKNODE_KEY}/`,
    aeneid: "https://aeneid.storyrpc.io",
    story: "https://mainnet.storyrpc.io",
  }[network];

  if (!host) {
    throw new Error(`Unknown blockscout RPC host for network ${network}`);
  }

  return `https://${host}`;
}

export async function get(url, data) {
  const res = (await axios.get(url, { params: data }))['data'];
  return res;
}

