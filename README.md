# Hero Network

**Trust Infrastructure for Autonomous Systems on Arbitrum**

Hero Network provides infrastructure for autonomous AI agents to interact securely, execute confidentially, and maintain verifiable context on Arbitrum.

## Core Primitives

| Primitive | Implementation |
|-----------|---------------|
| Agent Identity | ERC-4337 Account Abstraction on Arbitrum |
| Confidential Execution | Fhenix CoFHE (FHE coprocessor, live on Arbitrum) |
| Verifiable Execution | ZK proofs (Halo2/PLONK input/output commitments) |
| Verifiable Memory | On-chain Merkle root commitments + off-chain indexed graphs |

## Architecture

```
+------------------+
|   Agent Layer    |
+--------+---------+
         |
+--------v---------+
|  Hero Protocol   |
|  - Identity      |
|  - Memory        |
|  - Confidential  |
|    Execution     |
|    (via CoFHE)   |
+--------+---------+
         |
+--------v---------+
|  Arbitrum One    |
|  (Settlement)    |
+------------------+
```

## How It Works: Confidential Autonomous Workflows

1. Agent submits encrypted task
2. Computation via Fhenix CoFHE (data stays encrypted)
3. Cryptographic attestation generated
4. Proof recorded on Arbitrum
5. Settlement via smart contracts

## Target Use Cases

- Autonomous financial agents
- Enterprise automation with confidential business logic
- Research agents accessing restricted datasets
- Machine-to-machine service coordination

## Project Status

Architecture-complete, pre-MVP.

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | Agent identity contracts, memory commitment layer, CoFHE integration | In progress |
| Phase 2 | SDK, developer tooling, memory indexing | Planned |
| Phase 3 | Mainnet deployment on Arbitrum One | Planned |

## Tech Stack

- **Blockchain:** Arbitrum One (L2)
- **Confidential Compute:** Fhenix CoFHE
- **Smart Contracts:** Solidity 0.8.20 (Foundry)
- **Proof System:** Halo2/PLONK-style SNARKs
- **Agent Accounts:** ERC-4337

## Contracts

- [`AgentRegistry.sol`](contracts/src/AgentRegistry.sol) - Registry for autonomous agent identities with delegation support
- [`MemoryCommitment.sol`](contracts/src/MemoryCommitment.sol) - On-chain commitment layer for verifiable agent memory
- [`WorkflowSettlement.sol`](contracts/src/WorkflowSettlement.sol) - Workflow lifecycle management with escrow settlement

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Agent Identity](docs/agent-identity.md)
- [Confidential Execution](docs/confidential-execution.md)
- [Verifiable Memory](docs/verifiable-memory.md)

## Build & Test

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Build
forge build

# Test
forge test -vvv
```

## Team

- **Tracey Bowen** - Founder & CEO. AI Ethics Researcher (Mozilla), RadicalxChange Fellow, DeSci World Fellow, Research England funded researcher. Background in Law. Founded H.E.R. DAO.
- **Joy** - Technical Co-Founder & CTO. Protocol engineer, 6+ years blockchain infrastructure. Led Mandala Chain development. Aquarium Incubator finalist. Part-time Professor at George Brown College Toronto.

## License

MIT