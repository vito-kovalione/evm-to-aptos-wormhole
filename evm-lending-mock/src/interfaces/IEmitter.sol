// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEmitterEvents} from "./IEmitterEvents.sol";

interface IEmitter is IEmitterEvents {
    function sendLockCollateralMsg(
        uint16 destinationChainId,
        address tokenAddress, 
        uint256 amount, 
        address owner,
        bytes32 receiverAddress
    ) external payable;
}