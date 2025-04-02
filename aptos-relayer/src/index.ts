import { ethers } from 'ethers';
import { ETH_RPC_URL, POLLING_INTERVAL_MS, START_BLOCK, validateConfig, EMITTER_ADDRESS, APTOS_MODULE_ADDRESS } from './config';
import { createWormholeProvider, fetchSignedVAA, parseWormholeVAA, decodeEmitterPayload } from './wormhole';
import { processWormholeMessage } from './aptos';

// Store processed sequences to avoid duplicates
const processedSequences = new Set<string>();


async function processWormholeEvent(
  sender: string,
  sequence: bigint,
  nonce: number,
  payload: string,
  consistencyLevel: number
) {
  try {
    const sequenceStr = sequence.toString();

    if (sender !== EMITTER_ADDRESS) {
      // console.log(`Skipping event from non-emitter address: ${sender}`);
      return;
    }
    
    // Skip if already processed
    if (processedSequences.has(sequenceStr)) {
      console.log(`Sequence ${sequenceStr} already processed, skipping`);
      return;
    }
    
    console.log(`Processing new message: sequence=${sequenceStr}, sender=${sender}`);
    
    const vaaBytes = await fetchSignedVAA(sequence);
    
    const parsedVaa = parseWormholeVAA(vaaBytes);

    const decodedPayload = decodeEmitterPayload(parsedVaa.payload);
    
    console.log(`Decoded payload: token=${decodedPayload.tokenAddress}, amount=${decodedPayload.amount}, owner=${decodedPayload.owner}, receiverAddress=${decodedPayload.receiverAddress}`);
    
    // Process the message on Aptos
    if (decodedPayload.destinationChainId == 22) {
      const txHash = await processWormholeMessage(parsedVaa, vaaBytes, decodedPayload);
      console.log(`Successfully relayed message to Aptos: ${txHash}`);
    } else {
      console.log(`Skipping message to non-Aptos chain: ${decodedPayload.destinationChainId}`);
    }
    
    processedSequences.add(sequenceStr);
  } catch (error) {
    console.error(`Error processing Wormhole event: ${error}`);
  }
}


async function startRelayer() {
  try {
    validateConfig();
    
    console.log('Starting Aptos Relayer...');
    console.log(`Listening for events from block ${START_BLOCK}`);
    
    const wormholeContract = createWormholeProvider(ETH_RPC_URL);
    
    const provider = new ethers.JsonRpcProvider(ETH_RPC_URL);
    const currentBlock = await provider.getBlockNumber();
    
    let fromBlock = START_BLOCK > 0 ? START_BLOCK : currentBlock;
    
    console.log(`Starting from block ${fromBlock}`);
    
    wormholeContract.on(
      'LogMessagePublished',
      async (sender, sequence, nonce, payload, consistencyLevel, event) => {
        console.log(`New LogMessagePublished event detected at block ${event.blockNumber}`);
        await processWormholeEvent(sender, sequence, nonce, payload, consistencyLevel);
      }
    );
    
    // Periodically check for past events that might have been missed
    setInterval(async () => {
      try {
        const latestBlock = await provider.getBlockNumber();
        
        if (fromBlock < latestBlock) {
          console.log(`Checking for missed events from block ${fromBlock} to ${latestBlock}`);
          
          const events = await wormholeContract.queryFilter(
            wormholeContract.filters.LogMessagePublished(),
            fromBlock,
            latestBlock
          );
          
          for (const event of events) {
            // Check if the event is an EventLog (which has args) and not just a Log
            if ('args' in event && event.args) {
              const [sender, sequence, nonce, payload, consistencyLevel] = event.args;
              await processWormholeEvent(sender, sequence, nonce, payload, consistencyLevel);
            }
          }
          
          // Update the from block for the next check
          fromBlock = latestBlock + 1;
        }
      } catch (error) {
        console.error(`Error checking for past events: ${error}`);
      }
    }, POLLING_INTERVAL_MS);
    
    console.log('Relayer is running and listening for events...');
  } catch (error) {
    console.error(`Failed to start relayer: ${error}`);
    process.exit(1);
  }
}

// Start the relayer
startRelayer().catch((error) => {
  console.error(`Unhandled error: ${error}`);
  process.exit(1);
}); 