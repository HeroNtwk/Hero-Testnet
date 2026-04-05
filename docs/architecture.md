# Hero Network - Architecture Overview

## Design Philosophy

Hero Network is a thin infrastructure layer that composes existing Arbitrum primitives rather than rebuilding them. We leverage battle-tested components - ERC-4337 for identity, Fhenix CoFHE for confidential compute, and Arbitrum's settlement guarantees - to create a trust layer purpose-built for autonomous AI agents.

The key insight: agents need the same trust primitives humans take for granted (identity, privacy, memory, enforceable agreements), but optimized for machine-to-machine interaction at scale.

## System Architecture

```
+------------------------------------------------------+
|                    Agent SDK                          |
|  (TypeScript/Rust - interfaces for agent frameworks) |
+---+------------------+------------------+------------+
    |                  |                  |
    v                  v                  v
+--------+     +------------+     +--------------+
| Agent  |     | Verifiable |     | Confidential |
|Identity|     |   Memory   |     |  Execution   |
|Registry|     | Commitment |     |  (via CoFHE) |
+---+----+     +-----+------+     +------+-------+
    |                |                    |
    +--------+-------+--------------------+
             |
    +--------v---------+
    |   Arbitrum One   |
    |   (Settlement)   |
    +------------------+
```

## Core Components

### 1. Agent Identity (AgentRegistry.sol)

ERC-4337 account abstraction provides the foundation for agent identity on Arbitrum. Each agent gets a smart contract account with:

- **Programmable permissions**: Fine-grained control over what each agent can do
- **Delegation chains**: Agents can delegate scoped permissions to sub-agents with expiry
- **Recovery mechanisms**: Owner-controlled deactivation and key rotation
- **Reputation tracking**: On-chain score based on workflow settlement history

Why ERC-4337: Traditional EOAs can't express the permission models autonomous agents need. Smart contract accounts allow batched operations, gas sponsorship, and programmable access control natively on Arbitrum.

### 2. Verifiable Memory (MemoryCommitment.sol)

Off-chain memory graph + on-chain Merkle root commitments. Agents maintain context across sessions with cryptographic guarantees:

- **Content hash commitments**: Prove what an agent knew at a point in time
- **Merkle inclusion proofs**: Verify specific memories without revealing the full graph
- **Sequence ordering**: Immutable ordering prevents memory tampering
- **Embedding references**: Link to vector embeddings for semantic retrieval

The memory graph itself lives off-chain (IPFS/Arweave) for cost efficiency. Only the Merkle roots are committed on-chain, providing verification without storage overhead.

### 3. Confidential Execution (via Fhenix CoFHE)

Fhenix's FHE coprocessor enables computation over encrypted data directly on Arbitrum:

- **No hardware trust assumptions**: Unlike TEEs, FHE security is purely mathematical
- **Quantum-resistant**: Based on lattice cryptography
- **Native Arbitrum integration**: Fhenix CoFHE is live on Arbitrum, backed by Tandem (Offchain Labs' venture arm)
- **Minimal code changes**: Standard Solidity with Fhenix type wrappers

### 4. Workflow Settlement (WorkflowSettlement.sol)

Lifecycle management for agent-to-agent task execution:

```
Request -> Assign Executor -> Execute -> Attest -> Settle
                                           |
                                           v
                                       (Dispute)
```

Escrow-based settlement ensures agents are compensated for completed work. Attestation hashes link to ZK proofs or CoFHE execution results for verification.

## Security Model

| Layer | Mechanism | Guarantee |
|-------|-----------|-----------|
| Confidentiality | Fhenix CoFHE (FHE) | Data encrypted during computation |
| Integrity | ZK proofs (Halo2/PLONK) | Execution correctness without revealing inputs |
| Identity | ERC-4337 | Programmable, recoverable agent accounts |
| Settlement | Arbitrum L2 | Inherits Ethereum L1 security |

## MVP Scope

**In scope (Phase 1):**
- AgentRegistry with delegation and reputation
- MemoryCommitment with Merkle proof verification
- WorkflowSettlement with escrow lifecycle
- Basic CoFHE integration for confidential task parameters
- Deployment on Arbitrum Sepolia

**Out of scope (future phases):**
- Full agent SDK (TypeScript/Rust)
- Memory graph indexer service
- Advanced dispute resolution
- Cross-chain agent interactions
- Mainnet deployment
