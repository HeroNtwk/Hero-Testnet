// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MemoryCommitment
/// @notice On-chain commitment layer for verifiable agent memory
/// @dev Stores Merkle roots and content hashes for off-chain memory graphs
contract MemoryCommitment {
    struct MemoryEntry {
        bytes32 agentId;
        bytes32 contentHash;
        bytes32 merkleRoot;
        bytes32 embeddingRef;
        uint256 timestamp;
        uint256 sequenceNumber;
    }

    mapping(bytes32 => uint256) public latestSequence;
    mapping(bytes32 => mapping(uint256 => MemoryEntry)) public memories;
    mapping(bytes32 => bytes32) public latestMerkleRoot;

    event MemoryCommitted(
        bytes32 indexed agentId,
        uint256 indexed sequenceNumber,
        bytes32 contentHash,
        bytes32 merkleRoot
    );
    event MemoryGraphUpdated(bytes32 indexed agentId, bytes32 newMerkleRoot);

    /// @notice Commit a new memory entry for an agent
    /// @param agentId The agent committing the memory
    /// @param contentHash Hash of the memory content stored off-chain
    /// @param merkleRoot Root of the Merkle tree containing all memory nodes
    /// @param embeddingRef Reference to the vector embedding (for semantic retrieval)
    function commitMemory(
        bytes32 agentId,
        bytes32 contentHash,
        bytes32 merkleRoot,
        bytes32 embeddingRef
    ) external {
        // TODO: Verify caller is authorized via AgentRegistry
        require(contentHash != bytes32(0), "MemoryCommitment: empty content hash");
        require(merkleRoot != bytes32(0), "MemoryCommitment: empty merkle root");

        uint256 seq = latestSequence[agentId];
        memories[agentId][seq] = MemoryEntry({
            agentId: agentId,
            contentHash: contentHash,
            merkleRoot: merkleRoot,
            embeddingRef: embeddingRef,
            timestamp: block.timestamp,
            sequenceNumber: seq
        });

        latestMerkleRoot[agentId] = merkleRoot;
        latestSequence[agentId] = seq + 1;

        emit MemoryCommitted(agentId, seq, contentHash, merkleRoot);
        emit MemoryGraphUpdated(agentId, merkleRoot);
    }

    /// @notice Verify that a memory entry matches the stored commitment
    /// @param agentId The agent that owns the memory
    /// @param sequenceNumber The sequence number of the memory entry
    /// @param contentHash The content hash to verify against
    /// @return valid True if the content hash matches the stored commitment
    function verifyMemory(
        bytes32 agentId,
        uint256 sequenceNumber,
        bytes32 contentHash
    ) external view returns (bool valid) {
        require(sequenceNumber < latestSequence[agentId], "MemoryCommitment: invalid sequence number");
        return memories[agentId][sequenceNumber].contentHash == contentHash;
    }

    /// @notice Get the latest memory entry for an agent
    /// @param agentId The agent to query
    /// @return The latest MemoryEntry
    function getLatestMemory(bytes32 agentId) external view returns (MemoryEntry memory) {
        uint256 seq = latestSequence[agentId];
        require(seq > 0, "MemoryCommitment: no memories for agent");
        return memories[agentId][seq - 1];
    }

    /// @notice Verify a Merkle inclusion proof
    /// @dev Standard sorted-pair hashing for proof verification
    /// @param agentId The agent whose memory tree to verify against
    /// @param leaf The leaf node hash to prove inclusion of
    /// @param proof The Merkle proof (array of sibling hashes)
    /// @return valid True if the proof is valid against the agent's latest Merkle root
    function verifyMerkleProof(
        bytes32 agentId,
        bytes32 leaf,
        bytes32[] calldata proof
    ) external view returns (bool valid) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == latestMerkleRoot[agentId];
    }

    /// @notice Get the total number of memory entries for an agent
    /// @param agentId The agent to query
    /// @return count Number of committed memories
    function getMemoryCount(bytes32 agentId) external view returns (uint256 count) {
        return latestSequence[agentId];
    }
}