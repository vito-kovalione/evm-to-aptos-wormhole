// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Emitter} from "../src/Emitter.sol";
import {LendingPoolMock} from "../src/LendingPoolMock.sol";

// forge script Run --rpc-url https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY --broadcast --legacy --verify
contract Run is Script {
    uint16 public constant APTOS_CHAIN_ID = 22;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        LendingPoolMock lendingPool = LendingPoolMock(0xf47279121c443664D373A64Bf25D648DE83Aed36);

        address tokenAddress = address(0x0000000000000000000000000000000000000004);
        uint256 amount = 1000;
        bytes32 receiverAddress = bytes32(0xf07429c6173a074bbaac677bf876efbc23a9ab4901e5f355d1add2ee9babaf4d);
        
        // Deposit tokens first
        lendingPool.deposit(tokenAddress, amount);
        
        // Calculate the expected message hash for logging purposes
        bytes32 messageHash = keccak256(abi.encodePacked(
            APTOS_CHAIN_ID,
            tokenAddress,
            amount,
            deployer,
            receiverAddress
        ));
        
        console.log("Expected message hash:", uint256(messageHash));

        // Lock collateral and send through Wormhole
        // Include enough ETH to cover the Wormhole fee
        lendingPool.lockCollateralForAptos{value: 0.01 ether}(
            tokenAddress, 
            APTOS_CHAIN_ID,
            amount, 
            receiverAddress
        );

        vm.stopBroadcast();
    }
}


