// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEmitter} from "./interfaces/IEmitter.sol";

contract LendingPoolMock {
    struct Position {
        uint256 amount;
        bool isLocked;
    }

    IEmitter public immutable emitter;
    mapping(address => mapping(address => Position)) public positions;

    constructor(address _emitter) {
        emitter = IEmitter(_emitter);
    }

    function deposit(address token, uint256 amount) external {
        if (positions[msg.sender][token].amount == 0) { 
            positions[msg.sender][token] = Position(amount, false);
        } else {
            positions[msg.sender][token].amount += amount;
        }
    }

    function withdraw(address token, uint256 amount) external {
        require(!positions[msg.sender][token].isLocked, "position is locked");
        require(positions[msg.sender][token].amount >= amount, "insufficient balance");
        positions[msg.sender][token].amount -= amount;
    }

    function lockCollateralForAptos(
        address token, 
        uint16 destinationChainId, 
        uint256 amount, 
        bytes32 receiverAddress
    ) external payable {
        require(!positions[msg.sender][token].isLocked, "position is already locked");
        positions[msg.sender][token].isLocked = true;
        emitter.sendLockCollateralMsg{value: msg.value}(
            destinationChainId, 
            token,
            amount, 
            msg.sender,
            receiverAddress
        );
    }
}
