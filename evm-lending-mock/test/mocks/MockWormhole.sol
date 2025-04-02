// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IWormhole {
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }
    
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }
    
    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }
    
    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);
    
    function messageFee() external view returns (uint256);
    function lastPayload() external view returns (bytes memory);
    
    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);
    function verifyVM(VM memory vm) external pure returns (bool);
    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool);
    function getGuardianSet(uint32 index) external pure returns (GuardianSet memory);
    function getCurrentGuardianSetIndex() external pure returns (uint32);
    function getGuardianSetExpiry() external pure returns (uint32);
    function governanceActionIsConsumed(bytes32 hash) external pure returns (bool);
    function isInitialized(address impl) external pure returns (bool);
    function chainId() external pure returns (uint16);
    function governanceChainId() external pure returns (uint16);
    function governanceContract() external pure returns (bytes32);
    function implementation() external pure returns (address);
}

contract MockWormhole is IWormhole {
    bytes private _lastPayload;
    uint256 private _messageFee = 0.001 ether;
    
    function publishMessage(
        uint32 /* nonce */,
        bytes memory payload,
        uint8 /* consistencyLevel */
    ) external payable returns (uint64 sequence) {
        require(msg.value >= _messageFee, "insufficient value");
        _lastPayload = payload;
        return 1; // Return a dummy sequence number
    }
    
    function messageFee() external view returns (uint256) {
        return _messageFee;
    }

    function lastPayload() external view returns (bytes memory) {
        return _lastPayload;
    }
    
    // Implement other required functions from IWormhole with minimal functionality
    function parseVM(bytes memory /* encodedVM */) external pure returns (VM memory vm) {
        return VM({
            version: 0,
            timestamp: 0,
            nonce: 0,
            emitterChainId: 0,
            emitterAddress: bytes32(0),
            sequence: 0,
            consistencyLevel: 0,
            payload: new bytes(0),
            guardianSetIndex: 0,
            signatures: new Signature[](0),
            hash: bytes32(0)
        });
    }
    
    function verifyVM(VM memory /* vm */) external pure returns (bool) {
        return true;
    }
    
    function verifySignatures(bytes32 /* hash */, Signature[] memory /* signatures */, GuardianSet memory /* guardianSet */) external pure returns (bool) {
        return true;
    }
    
    function getGuardianSet(uint32 /* index */) external pure returns (GuardianSet memory) {
        return GuardianSet({
            keys: new address[](0),
            expirationTime: 0
        });
    }
    
    function getCurrentGuardianSetIndex() external pure returns (uint32) {
        return 0;
    }
    
    function getGuardianSetExpiry() external pure returns (uint32) {
        return 0;
    }
    
    function governanceActionIsConsumed(bytes32 /* hash */) external pure returns (bool) {
        return false;
    }
    
    function isInitialized(address /* impl */) external pure returns (bool) {
        return true;
    }
    
    function chainId() external pure returns (uint16) {
        return 1;
    }
    
    function governanceChainId() external pure returns (uint16) {
        return 1;
    }
    
    function governanceContract() external pure returns (bytes32) {
        return bytes32(0);
    }
    
    function implementation() external pure returns (address) {
        return address(0);
    }
} 