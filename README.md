# AAVE to Aptos Bridge

This project demonstrates a cross-chain lending protocol integration between Ethereum and Aptos using Wormhole as the messaging layer. It allows users to lock collateral on Ethereum and use it on Aptos.

## Project Overview

The project consists of three main components:

1. **EVM Lending Mock** (`evm-lending-mock/`): A simplified mock of an EVM lending protocol that can lock collateral for use on Aptos via Wormhole.
2. **Aptos Relayer** (`aptos-relayer/`): A custom relayer that listens for Wormhole messages from Ethereum and delivers them to Aptos.
3. **Aptos Module** (`aptos-module/`): A Move module that receives and processes Wormhole messages on Aptos.

## Prerequisites

- [Node.js](https://nodejs.org/) (v16 or later)
- [Foundry](https://getfoundry.sh/) for Ethereum contract development
- [Aptos CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/) for Aptos development
- Access to Ethereum Sepolia testnet (via RPC)
- Access to Aptos testnet

## Setup and Testing

### 1. Deploy and Run EVM Lending Mock

Navigate to the EVM lending mock directory:

```bash
cd evm-lending-mock
```

Install dependencies and compile contracts:

```bash
npm install
forge build
```

Run the test script to emit a message:

```bash
forge script Run --rpc-url https://1rpc.io/sepolia --broadcast --legacy
```

Take note of the block number where the contract was deployed, as you'll need it for the relayer.

### 2 aptos-module is already deployed for test run 

### 3. Configure and Run Aptos Relayer

Navigate to the Aptos relayer directory:

```bash
cd aptos-relayer
```

Install dependencies:

```bash
npm install
```

Edit the `.env` file and set the `START_BLOCK` value to the block number from the previous step.
Note: it's possible that block is not executed yet, in this case patience is needed

Build and start the relayer:

```bash
npm run build
npm start
```

The relayer will now listen for events from the EVM lending mock and relay them to Aptos.

## Monitoring and Verification

Once the relayer processes a message, you can verify the transaction on the Aptos explorer:

```
https://explorer.aptoslabs.com/account/0x56fc98c8d4d659918a3cdca57ad9d42b59756088e0f68ad94cba3e073c0c7cc8?network=testnet
```

## Project Structure

- `evm-lending-mock/`: Contains the Ethereum contracts for the mock lending protocol
- `aptos-relayer/`: Contains the TypeScript code for the Wormhole relayer
- `aptos-module/`: Contains the Move modules for the Aptos side of the bridge

