# EVM Lending Mock

This project contains a mock implementation of an EVM lending protocol that can lock collateral for use on Aptos via Wormhole.

## Overview

The project consists of two main contracts:

1. `LendingPoolMock`: A simplified lending pool that allows users to deposit, withdraw, and lock collateral for Aptos.
2. `Emitter`: A contract that emits Wormhole messages when collateral is locked.

## Test run with existing setup

1. Install dependencies:

```bash
npm install
```

2. Compile the contracts:

```bash
npm run compile
```

```
forge script Run --rpc-url https://1rpc.io/sepolia --broadcast --legacy
```

## Testing

We've created a simplified testing approach that doesn't require external dependencies like Foundry or Hardhat. To run the tests:

1. Start a local Ethereum node (e.g., Ganache):

```bash
# Install Ganache if you don't have it
npm install -g ganache-cli

# Start a local Ethereum node
ganache-cli
```

2. Deploy the test contracts:

```bash
npm run deploy
```

3. Run the tests:

```bash
npm run test
```

For more details about the tests, see the [test README](./test/README.md).

## Contract Details

### LendingPoolMock

The `LendingPoolMock` contract provides the following functionality:

- `deposit(address token, uint256 amount)`: Deposit tokens into the lending pool.
- `withdraw(address token, uint256 amount)`: Withdraw tokens from the lending pool.
- `lockCollateralForAptos(address token, uint16 destinationChainId, uint256 amount, bytes32 receiverAddress)`: Lock collateral for use on Aptos.

### Emitter

The `Emitter` contract provides the following functionality:

- `sendLockCollateralMsg(uint16 destinationChainId, address tokenAddress, uint256 amount, address owner, bytes32 receiverAddress)`: Send a message to Aptos via Wormhole when collateral is locked.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
