# Aptos Relayer for Wormhole

A custom relayer for delivering Wormhole messages from Ethereum to Aptos. This relayer listens for `LogMessagePublished` events from the Wormhole Core Bridge contract on Ethereum, fetches the signed VAAs from the Wormhole Guardian network, and delivers them to an Aptos module.

## Setup

1. Clone the repository
2. Install dependencies:
```bash
npm install
```
3. Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```
4. Fill in the required environment variables in the `.env` file:
```
# Ethereum (Source Chain)
ETH_RPC_URL=https://sepolia.infura.io/v3/your-api-key
EMITTER_ADDRESS=0xe116aa2640dcbcBd216CEc7Cc403992DE2168036
WORMHOLE_CORE_BRIDGE=0x4a8bc80Ed5a4067f1CCf107057b8270E0cC11A78

# Aptos (Target Chain)
APTOS_NODE_URL=https://fullnode.testnet.aptoslabs.com/v1
APTOS_PRIVATE_KEY=your_aptos_private_key
APTOS_MODULE_ADDRESS=your_aptos_module_address

# Wormhole Configuration
WORMHOLE_RPC_HOST=https://wormhole-v2-testnet-api.certus.one

# Relayer Configuration
POLLING_INTERVAL_MS=5000
START_BLOCK=0
```

## Building the Relayer

```bash
npm run build
```

## Running the Relayer

```bash
npm start
```

For development with hot reloading:
```bash
npm run dev
```

## How It Works

1. The relayer listens for `LogMessagePublished` events from the Wormhole Core Bridge contract on Ethereum
2. When an event is detected, it fetches the signed VAA from the Wormhole Guardian network
3. It parses the VAA and decodes the payload from the Emitter contract
4. It submits a transaction to the Aptos module to process the Wormhole message
