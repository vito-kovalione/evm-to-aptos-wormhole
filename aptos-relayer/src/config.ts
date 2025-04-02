import dotenv from 'dotenv';
import { ethers } from 'ethers';

// Load environment variables
dotenv.config();

// Ethereum (Source Chain) Configuration
export const ETH_RPC_URL = process.env.ETH_RPC_URL || 'https://sepolia.infura.io/v3/your-api-key';
export const EMITTER_ADDRESS = process.env.EMITTER_ADDRESS || '0xe116aa2640dcbcBd216CEc7Cc403992DE2168036';
export const WORMHOLE_CORE_BRIDGE = process.env.WORMHOLE_CORE_BRIDGE || '0x4a8bc80Ed5a4067f1CCf107057b8270E0cC11A78';

// Aptos (Target Chain) Configuration
export const APTOS_NODE_URL = process.env.APTOS_NODE_URL || 'https://fullnode.testnet.aptoslabs.com/v1';
export const APTOS_PRIVATE_KEY = process.env.APTOS_PRIVATE_KEY || '';
export const APTOS_MODULE_ADDRESS = process.env.APTOS_MODULE_ADDRESS || '';

// Wormhole Configuration
export const WORMHOLE_RPC_HOST = process.env.WORMHOLE_RPC_HOST || 'https://wormhole-v2-testnet-api.certus.one';

// Relayer Configuration
export const POLLING_INTERVAL_MS = parseInt(process.env.POLLING_INTERVAL_MS || '5000');
export const START_BLOCK = parseInt(process.env.START_BLOCK || '0');

// Chain IDs
export const ETH_CHAIN_ID = 10002; // Sepolia in Wormhole format
export const APTOS_CHAIN_ID = 22; // Aptos testnet in Wormhole format

// Validate configuration
export function validateConfig() {
  if (!APTOS_PRIVATE_KEY) {
    throw new Error('APTOS_PRIVATE_KEY is required');
  }
  
  if (!APTOS_MODULE_ADDRESS) {
    throw new Error('APTOS_MODULE_ADDRESS is required');
  }
  
  try {
    new ethers.JsonRpcProvider(ETH_RPC_URL);
  } catch (error) {
    throw new Error(`Invalid ETH_RPC_URL: ${error}`);
  }
} 