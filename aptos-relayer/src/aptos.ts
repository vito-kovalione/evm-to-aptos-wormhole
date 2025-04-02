import { Aptos, AptosConfig, Ed25519PrivateKey, Account, PrivateKeyVariants, PrivateKey, Network } from '@aptos-labs/ts-sdk';
import { APTOS_NODE_URL, APTOS_PRIVATE_KEY, APTOS_MODULE_ADDRESS } from './config';

/**
 * Ensures an address is properly formatted for Aptos (padded to 64 characters)
 */
function formatAptosAddress(address: string): string {
  // Remove '0x' prefix if present
  const cleanAddress = address.startsWith('0x') ? address.slice(2) : address;
  // Pad to 64 characters
  return cleanAddress.padStart(64, '0');
}

/**
 * Submits a transaction to process a Wormhole message on Aptos
 */
export async function processWormholeMessage(
  parsedVaa: any,
  vaaBytes: Uint8Array,
  decodedPayload: any
): Promise<string> {
  const config = new AptosConfig({ network: Network.TESTNET });
  const aptos = new Aptos(config);
  const privateKey = PrivateKey.formatPrivateKey(APTOS_PRIVATE_KEY, PrivateKeyVariants.Ed25519);
  const account = Account.fromPrivateKey({ privateKey: new Ed25519PrivateKey(privateKey) });
  
  console.log(`Processing message for Aptos receiver: ${decodedPayload.receiverAddress}`);

  try {
    const formattedOwner = formatAptosAddress(decodedPayload.owner);
    const formattedTokenAddress = formatAptosAddress(decodedPayload.tokenAddress);
    console.log(`decodedPayload.destinationChainId: ${decodedPayload.destinationChainId}`);

    const transaction = await aptos.transaction.build.simple({
      sender: account.accountAddress,
      data: {
        function: `${APTOS_MODULE_ADDRESS}::wormhole_receiver::process_message`,
        functionArguments: [
          vaaBytes,
          decodedPayload.destinationChainId.toString(),
          formattedTokenAddress,
          decodedPayload.amount.toString(),
          formattedOwner,
          decodedPayload.messageHash,
        ]
      },
    });
    
    const committedTransaction = await aptos.transaction.signAndSubmitTransaction({signer: account, transaction});
    
    // Wait for transaction to be confirmed
    const txnResult = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    
    console.log(`Transaction submitted successfully: ${txnResult.hash}`);
    return txnResult.hash;
  } catch (error) {
    console.error(`Error submitting Aptos transaction: ${error}`);
    throw error;
  }
} 