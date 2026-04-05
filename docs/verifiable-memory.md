# Verifiable Memory

## The Problem

AI agents lose context between sessions. When an agent makes a decision, there's no way to verify what information it had access to, whether its memory has been tampered with, or even that it's working from the same context as before.

For autonomous agents handling financial transactions, legal documents, or sensitive business logic, this is unacceptable. Memory must be verifiable.

## Architecture

Hero's verifiable memory uses a hybrid on-chain/off-chain design:

```
Off-chain                          On-chain
+-------------------+              +-------------------+
| Memory Graph DB   |              | MemoryCommitment  |
| (IPFS / Arweave)  |  ------->   | Contract          |
|                   |  Merkle Root |                   |
| - Observations    |              | - contentHash     |
| - Decisions       |              | - merkleRoot      |
| - Tool Outputs    |              | - embeddingRef    |
| - Embeddings      |              | - sequenceNumber  |
+-------------------+              +-------------------+
```

**Off-chain**: The full memory graph with all content, embeddings, and relationships. Stored on IPFS or Arweave for persistence and content-addressability.

**On-chain**: Only the Merkle root commitments. This provides cryptographic verification without the storage cost of putting full memory graphs on-chain.

## Commitment Model

Each memory entry contains:

| Field | Type | Description |
|-------|------|-------------|
| agentId | bytes32 | The agent this memory belongs to |
| contentHash | bytes32 | Hash of the actual memory content |
| merkleRoot | bytes32 | Root of the Merkle tree containing all memory nodes |
| embeddingRef | bytes32 | Reference to the vector embedding for semantic retrieval |
| timestamp | uint256 | Block timestamp when committed |
| sequenceNumber | uint256 | Monotonically increasing counter per agent |

## Verification Capabilities

### 1. Existence Proof
Verify that an agent committed a specific piece of memory at a specific time.
```
verifyMemory(agentId, sequenceNumber, contentHash) -> bool
```

### 2. Inclusion Proof (Merkle)
Verify that a specific memory node exists within the agent's memory graph without revealing the full graph.
```
verifyMerkleProof(agentId, leaf, proof[]) -> bool
```

### 3. Ordering Proof
Sequence numbers are monotonically increasing and immutable. This proves temporal ordering of memory commits.

### 4. Integrity Proof
The Merkle root changes with every commit. Any tampering with the off-chain memory graph will produce a different root than what's stored on-chain.

## Memory Graph Structure

The off-chain memory graph is a directed acyclic graph (DAG) with typed nodes and edges:

**Node Types:**
- `observation` - Raw data the agent perceived (API responses, sensor data, user input)
- `decision` - A choice the agent made with reasoning
- `tool_output` - Results from tool/function calls
- `summary` - Compressed representation of multiple nodes

**Edge Types:**
- `caused_by` - This node was triggered by another node
- `derived_from` - This node was computed from another node's data
- `supersedes` - This node replaces an older version

## Use Cases

### Financial Agent Audit Trail
A trading agent commits memory after every portfolio decision. Auditors can verify what data the agent had access to at any point, prove the sequence of decisions, and check for tampering, all without accessing the actual financial data.

### Research Agent Provenance
A research agent processing restricted datasets commits Merkle proofs of which data subsets it accessed. Data owners can verify compliance without seeing the agent's analysis.

### Multi-Agent Coordination
When Agent A hands off work to Agent B, B can verify A's memory commitments to ensure it's working from authentic context, not fabricated state.

## MVP Scope

**Implemented:**
- On-chain memory commitment with content hash and Merkle root
- Memory verification by content hash
- Merkle inclusion proof verification (sorted-pair hashing)
- Sequence number ordering
- Latest memory retrieval
- Memory count tracking

**Future work:**
- Off-chain memory graph indexer (SubQuery or custom)
- Vector embedding storage and retrieval service
- Memory graph visualization tools
- Cross-agent memory verification protocols
- Memory pruning and archival strategies
