# Aptos Lending Pool Mock

This project implements a wormhole receiver contract that consumes wormhole message and store data about locked collateral on other chains.

## Modules

### Wormhole Receiver (`wormhole_receiver.move`)

The wormhole receiver module handles cross-chain messages and stores collateral information. It supports:

- Processing messages from other chains (e.g., Ethereum)
- Storing collateral data
- Retrieving collateral information

## Testing

To run tests:
   aptos move test
## Deployment

To deploy this project:

1. Compile the modules:
   ```
   aptos move compile
   ```

2. Publish the modules:
   ```
   aptos move publish
   ```
