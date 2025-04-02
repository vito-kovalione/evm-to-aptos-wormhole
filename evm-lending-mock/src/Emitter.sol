// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IWormhole} from "wormhole-solidity-sdk/interfaces/IWormhole.sol";

import {IEmitter} from "./interfaces/IEmitter.sol";

contract Emitter is IEmitter {
    uint8 public constant CONSISTENCY_LEVEL = 1;

    IWormhole public immutable wormhole;

    constructor(address _wormhole) {
        wormhole = IWormhole(_wormhole);
    }
    
    function sendLockCollateralMsg(
        uint16 destinationChainId,
        address tokenAddress, 
        uint256 amount, 
        address owner,
        bytes32 receiverAddress
    ) external payable {
        // Create message hash for tracking
        bytes32 messageHash = keccak256(abi.encodePacked(
            destinationChainId,
            tokenAddress,
            amount,
            owner,
            receiverAddress
        ));

        // Encode the message for Aptos
        bytes memory payload = abi.encode(
            destinationChainId,
            tokenAddress,
            amount,
            owner,
            receiverAddress,
            messageHash
        );

        uint256 wormholeFee = wormhole.messageFee();

        // Send message via core Wormhole protocol
        wormhole.publishMessage{value: wormholeFee}(
            0, // nonce
            payload,
            CONSISTENCY_LEVEL
        );
        
        emit CollateralLocked(
            msg.sender,
            tokenAddress,
            destinationChainId,
            amount,
            block.timestamp,
            messageHash
        );
    }
}