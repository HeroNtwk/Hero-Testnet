// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MemoryCommitment.sol";

contract MemoryCommitmentTest is Test {
    MemoryCommitment public memory_;
    bytes32 public agentId = keccak256("agent-001");
    bytes32 public contentHash = keccak256("memory-content-v1");
    bytes32 public embeddingRef = keccak256("embedding-ref");

    function setUp() public {
        memory_ = new MemoryCommitment();
    }

    function testCommitMemory() public {
        bytes32 merkleRoot = keccak256("root-1");

        memory_.commitMemory(agentId, contentHash, merkleRoot, embeddingRef);

        assertEq(memory_.latestSequence(agentId), 1);
        assertEq(memory_.latestMerkleRoot(agentId), merkleRoot);
    }

    function testVerifyMemory() public {
        bytes32 merkleRoot = keccak256("root-1");

        memory_.commitMemory(agentId, contentHash, merkleRoot, embeddingRef);

        assertTrue(memory_.verifyMemory(agentId, 0, contentHash));
        assertFalse(memory_.verifyMemory(agentId, 0, keccak256("wrong-hash")));
    }

    function testSequenceOrdering() public {
        bytes32 content1 = keccak256("content-1");
        bytes32 content2 = keccak256("content-2");
        bytes32 root1 = keccak256("root-1");
        bytes32 root2 = keccak256("root-2");

        memory_.commitMemory(agentId, content1, root1, embeddingRef);
        memory_.commitMemory(agentId, content2, root2, embeddingRef);

        assertEq(memory_.latestSequence(agentId), 2);
        assertTrue(memory_.verifyMemory(agentId, 0, content1));
        assertTrue(memory_.verifyMemory(agentId, 1, content2));
        assertEq(memory_.latestMerkleRoot(agentId), root2);
    }

    function testGetLatestMemory() public {
        bytes32 merkleRoot = keccak256("root-1");

        memory_.commitMemory(agentId, contentHash, merkleRoot, embeddingRef);

        MemoryCommitment.MemoryEntry memory entry = memory_.getLatestMemory(agentId);
        assertEq(entry.agentId, agentId);
        assertEq(entry.contentHash, contentHash);
        assertEq(entry.merkleRoot, merkleRoot);
        assertEq(entry.sequenceNumber, 0);
    }

    function testGetLatestMemoryRevertsWhenEmpty() public {
        vm.expectRevert("MemoryCommitment: no memories for agent");
        memory_.getLatestMemory(agentId);
    }

    function testRejectsEmptyContentHash() public {
        vm.expectRevert("MemoryCommitment: empty content hash");
        memory_.commitMemory(agentId, bytes32(0), keccak256("root"), embeddingRef);
    }

    function testRejectsEmptyMerkleRoot() public {
        vm.expectRevert("MemoryCommitment: empty merkle root");
        memory_.commitMemory(agentId, contentHash, bytes32(0), embeddingRef);
    }

    function testMerkleProofVerification() public {
        // Build a simple 2-leaf Merkle tree
        bytes32 leaf1 = keccak256("leaf-1");
        bytes32 leaf2 = keccak256("leaf-2");

        bytes32 root;
        if (leaf1 <= leaf2) {
            root = keccak256(abi.encodePacked(leaf1, leaf2));
        } else {
            root = keccak256(abi.encodePacked(leaf2, leaf1));
        }

        memory_.commitMemory(agentId, contentHash, root, embeddingRef);

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = leaf2;
        assertTrue(memory_.verifyMerkleProof(agentId, leaf1, proof));

        // Invalid proof
        bytes32[] memory badProof = new bytes32[](1);
        badProof[0] = keccak256("bad-leaf");
        assertFalse(memory_.verifyMerkleProof(agentId, leaf1, badProof));
    }

    function testGetMemoryCount() public {
        assertEq(memory_.getMemoryCount(agentId), 0);

        memory_.commitMemory(agentId, contentHash, keccak256("root-1"), embeddingRef);
        assertEq(memory_.getMemoryCount(agentId), 1);

        memory_.commitMemory(agentId, keccak256("content-2"), keccak256("root-2"), embeddingRef);
        assertEq(memory_.getMemoryCount(agentId), 2);
    }

    function testVerifyMemoryRevertsOnInvalidSequence() public {
        vm.expectRevert("MemoryCommitment: invalid sequence number");
        memory_.verifyMemory(agentId, 0, bytes32(0));
    }
}
