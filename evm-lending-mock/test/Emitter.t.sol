// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {MockWormhole} from "./mocks/MockWormhole.sol";
import {console} from "./mocks/console.sol";

import "../src/Emitter.sol";
import "../src/interfaces/IEmitter.sol";
import "../src/interfaces/IEmitterEvents.sol";

contract EmitterTest is Test {
    Emitter public emitter;
    MockWormhole public wormhole;
    
    address public constant TOKEN_ADDRESS = address(0x1);
    address public constant OWNER = address(0x2);
    uint16 public constant DESTINATION_CHAIN_ID = 22; // Aptos chain ID
    bytes32 public constant RECEIVER_ADDRESS = bytes32(uint256(0x3));
    uint256 public constant AMOUNT = 100 ether;
    
    function setUp() public {
        wormhole = new MockWormhole();
        emitter = new Emitter(address(wormhole));
        
        // Set up the test user with some ETH for fees
        vm.deal(OWNER, 1 ether);
    }
    
    function testSendLockCollateralMsg() public {
        vm.recordLogs();

        // Create the expected event
        bytes32 expectedMessageHash = keccak256(abi.encodePacked(
            DESTINATION_CHAIN_ID,
            TOKEN_ADDRESS,
            AMOUNT,
            OWNER,
            RECEIVER_ADDRESS
        ));

        // Call the function as the owner
        vm.prank(OWNER);
        emitter.sendLockCollateralMsg{value: 0.001 ether}(
            DESTINATION_CHAIN_ID,
            TOKEN_ADDRESS,
            AMOUNT,
            OWNER,
            RECEIVER_ADDRESS
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(logs.length, 1);
        assertEq(logs[0].topics.length, 3);
        assertEq(logs[0].topics[0], IEmitterEvents.CollateralLocked.selector);
        assertEq(logs[0].topics[1], bytes32(uint256(uint160(OWNER))));
        assertEq(logs[0].topics[2], bytes32(uint256(uint160(TOKEN_ADDRESS))));
        assertEq(logs[0].data, abi.encode(DESTINATION_CHAIN_ID, AMOUNT, block.timestamp, expectedMessageHash));
    }
    
    function testFailInsufficientFee() public {
        // Try to call with insufficient fee (should fail)
        vm.prank(OWNER);
        emitter.sendLockCollateralMsg{value: 0.0005 ether}(
            DESTINATION_CHAIN_ID,
            TOKEN_ADDRESS,
            AMOUNT,
            OWNER,
            RECEIVER_ADDRESS
        );
    }
    
    function testMessagePayload() public {

        vm.deal(OWNER, 1 ether);
        
        vm.prank(OWNER);
        emitter.sendLockCollateralMsg{value: 0.001 ether}(
            DESTINATION_CHAIN_ID,
            TOKEN_ADDRESS,
            AMOUNT,
            OWNER,
            RECEIVER_ADDRESS
        );
        
        bytes memory payload = wormhole.lastPayload();
        
        (
            uint16 capturedDestinationChainId,
            address capturedTokenAddress,
            uint256 capturedAmount,
            address capturedOwner,
            bytes32 capturedReceiverAddress,
            bytes32 capturedMessageHash
        ) = abi.decode(payload, (uint16, address, uint256, address, bytes32, bytes32));
        
        // Verify the payload contents
        assertEq(capturedDestinationChainId, DESTINATION_CHAIN_ID);
        assertEq(capturedTokenAddress, TOKEN_ADDRESS);
        assertEq(capturedAmount, AMOUNT);
        assertEq(capturedOwner, OWNER);
        assertEq(capturedReceiverAddress, RECEIVER_ADDRESS);
        
        // Verify the message hash
        bytes32 expectedMessageHash = keccak256(abi.encodePacked(
            DESTINATION_CHAIN_ID,
            TOKEN_ADDRESS,
            AMOUNT,
            OWNER,
            RECEIVER_ADDRESS
        ));
        assertEq(capturedMessageHash, expectedMessageHash);
    }
}