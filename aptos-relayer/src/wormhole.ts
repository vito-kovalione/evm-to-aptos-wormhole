import { ethers } from 'ethers';
import { deserialize } from '@wormhole-foundation/sdk-definitions';
import axios from 'axios';
import { ETH_CHAIN_ID, EMITTER_ADDRESS, WORMHOLE_CORE_BRIDGE } from './config';

// Wormhole Core Bridge ABI (minimal for event listening)
const WORMHOLE_ABI = [
  'event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel)'
];


export function createWormholeProvider(rpcUrl: string): ethers.Contract {
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  return new ethers.Contract(WORMHOLE_CORE_BRIDGE, WORMHOLE_ABI, provider);
}


async function fetchVaaFromRestApi(
  chainId: number,
  emitterAddress: string,
  sequence: bigint
): Promise<Uint8Array | null> {
  try {
    // Format the emitter address as a hex string without the '0x' prefix
    const emitterAddressHex = emitterAddress.startsWith('0x') 
      ? emitterAddress.slice(2) 
      : emitterAddress;
    
    // this is workaround 
    const apiEndpoints = [
      `https://api.testnet.wormholescan.io/v1/signed_vaa/${chainId}/${emitterAddressHex}/${sequence}`,
      `https://api.testnet.wormhole.com/v1/signed_vaa/${chainId}/${emitterAddressHex}/${sequence}`,
      `https://wormhole-v2-testnet-api.certus.one/v1/signed_vaa/${chainId}/${emitterAddressHex}/${sequence}`,
      `https://wormhole-v2-testnet-api.guardiansofwormhole.com/v1/signed_vaa/${chainId}/${emitterAddressHex}/${sequence}`
    ];
    
  
    for (const apiUrl of apiEndpoints) {
      try {
        console.log(`Fetching VAA from REST API: ${apiUrl}`);
        
        // Make the request with a timeout of 10 seconds
        const response = await axios.get(apiUrl, { timeout: 10000 });
        
        // Different endpoints might have different response formats
        let vaaBytes: Buffer | null = null;
        
        if (response.data && response.data.vaaBytes) {
          // Format for certus.one and guardiansofwormhole.com
          vaaBytes = Buffer.from(response.data.vaaBytes, 'base64');
          console.log(`Found VAA in vaaBytes format`);
        } else if (response.data && response.data.data && response.data.data.vaa) {
          // Format for wormholescan.io
          vaaBytes = Buffer.from(response.data.data.vaa, 'base64');
          console.log(`Found VAA in data.vaa format`);
        } else if (response.data && typeof response.data === 'string') {
          // Some endpoints might return the VAA directly as a base64 string
          vaaBytes = Buffer.from(response.data, 'base64');
          console.log(`Found VAA as direct base64 string`);
        }
        
        if (vaaBytes && vaaBytes.length > 0) {
          console.log(`Successfully fetched VAA from REST API, length: ${vaaBytes.length}`);
          console.log(`First 20 bytes of VAA: ${Buffer.from(vaaBytes).slice(0, 20).toString('hex')}`);
          return new Uint8Array(vaaBytes);
        } else {
          console.log(`Response received but no VAA found in the expected format`);
          console.log(`Response data: ${JSON.stringify(response.data).substring(0, 200)}...`);
        }
      } catch (endpointError) {
        console.log(`Error fetching from ${apiUrl}: ${endpointError}`);
        // Continue to the next endpoint
      }
    }
    
    console.log(`No VAA found in any REST API response`);
    return null;
  } catch (error) {
    console.error(`Error fetching VAA from REST APIs: ${error}`);
    return null;
  }
}

export async function fetchSignedVAA(sequence: bigint): Promise<Uint8Array> {
  try {
    console.log(`Fetching VAA for sequence: ${sequence}`);
    
    // Convert emitter address to bytes32 format required by Wormhole
    const emitterAddressBytes = ethers.zeroPadValue(
      ethers.getBytes(EMITTER_ADDRESS),
      32
    );
    console.log(`Emitter address bytes: ${Buffer.from(emitterAddressBytes).toString('hex')}`);
    
    const vaaFromRest = await fetchVaaFromRestApi(
      ETH_CHAIN_ID,
      EMITTER_ADDRESS,
      sequence
    );
    
    if (vaaFromRest) {
      console.log(`Successfully fetched VAA from REST API`);
      return vaaFromRest;
    }
    
    throw new Error(`Failed to fetch VAA after trying all available methods. Please check if the Wormhole network is operational and if your sequence number ${sequence} is valid.`);
  } catch (error) {
    console.error(`Error fetching VAA: ${error}`);
    throw error;
  }
}

export function parseWormholeVAA(vaaBytes: Uint8Array) {
  try {
    console.log(`Parsing VAA of length: ${vaaBytes.length}`);
    console.log(`First 20 bytes of VAA: ${Buffer.from(vaaBytes).slice(0, 20).toString('hex')}`);
    
    let version = vaaBytes[0];
    const vaa = deserialize("Uint8Array", vaaBytes);

    console.log(`Version: ${version}`);
    console.log(`emitterAddress: ${vaa.emitterAddress}`);

    return {
      emitterChain: vaa.emitterChain,
      emitterAddress: vaa.emitterAddress,
      sequence: vaa.sequence,
      payload: vaa.payload,
      timestamp: vaa.timestamp,
      nonce: vaa.nonce,
      consistencyLevel: vaa.consistencyLevel,
      signatures: vaa.signatures
    };
  } catch (error) {
    console.error(`Error parsing VAA: ${error}`);
    throw error;
  }
}

export function decodeEmitterPayload(payload: Uint8Array) {
  try {
    console.log(`Decoding payload of length: ${payload.length}`);
    
    const decoder = new ethers.AbiCoder();
    
    // The payload format should match what's encoded in the Emitter.sol contract
    const decoded = decoder.decode(
      ['uint16', 'address', 'uint256', 'address', 'bytes32', 'bytes32'],
      payload
    );
    
    console.log(`Successfully decoded payload with token symbol: ${decoded[2]}`);
    return {
      destinationChainId: decoded[0],
      tokenAddress: decoded[1],
      amount: decoded[2],
      owner: decoded[3],
      receiverAddress: decoded[4],
      messageHash: decoded[5]
    };
  } catch (error) {
    console.error(`Error decoding payload: ${error}`);
    throw error;
  }
}
