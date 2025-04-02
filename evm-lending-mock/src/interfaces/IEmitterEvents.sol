// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IEmitterEvents {
    event CollateralLocked(
        address indexed owner, 
        address indexed tokenAddress, 
        uint16 destinationChainId,
        uint256 amount, 
        uint256 timestamp, 
        bytes32 messageHash
    );
}