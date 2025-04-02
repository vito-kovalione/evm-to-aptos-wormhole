# EVM Lending Mock Tests

This directory contains tests for the EVM Lending Mock contracts. The tests are written using a simplified testing approach that doesn't require external dependencies.

## Test Files

1. `LendingPoolMock.t.sol` - Tests for the LendingPoolMock contract
2. `Emitter.t.sol` - Tests for the Emitter contract

## Test Coverage

### LendingPoolMock Tests

- `testDeposit`: Tests the basic deposit functionality
- `testMultipleDeposits`: Tests multiple deposits to the same position
- `testWithdraw`: Tests the withdrawal functionality
- `testFailWithdrawTooMuch`: Tests that withdrawing more than the deposited amount fails
- `testLockCollateral`: Tests locking collateral for Aptos
- `testFailLockCollateralTwice`: Tests that locking the same collateral twice fails
- `testFailWithdrawLockedCollateral`: Tests that withdrawing locked collateral fails

### Emitter Tests

- `testSendLockCollateralMsg`: Tests the basic functionality of sending a lock collateral message
- `testFailInsufficientFee`: Tests that sending a message with insufficient fee fails
- `testMessagePayload`: Tests that the message payload is correctly formatted

## Running the Tests

To run these tests, you'll need to use a custom approach since we've created mock implementations of external dependencies:

1. First, make sure all the mock implementations are in place:
   - `src/mocks/MockWormhole.sol` - Mock implementation of the Wormhole contract
   - `src/mocks/console.sol` - Mock implementation of the console library

2. Compile the contracts:
```bash
cd evm-lending-mock
solc --bin --abi --optimize --optimize-runs=200 src/*.sol src/interfaces/*.sol src/mocks/*.sol test/*.sol -o build
```

3. Run the tests manually:
```bash
# Deploy the contracts
node scripts/deploy-test-contracts.js

# Run the tests
node scripts/run-tests.js
```

## Notes on Test Implementation

The tests use a simplified approach that doesn't require external dependencies:

1. We've created our own simplified Test interface instead of using Foundry's Test contract
2. We've created mock implementations of external dependencies:
   - `MockWormhole`: A mock implementation of the Wormhole contract for testing
   - `MockWormholeInterceptor`: A specialized mock that captures the payload for verification
   - `console`: A mock implementation of the console library for logging

These mocks allow us to test the contracts without requiring the actual Wormhole infrastructure or Foundry's testing framework.

## Known Issues

1. These tests are not using the standard Foundry testing approach, so they won't work with `forge test`. Instead, you'll need to run them manually as described above.

2. The tests are simplified and don't include all the features of a full testing framework, such as gas reporting, coverage analysis, etc. 