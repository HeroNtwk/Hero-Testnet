# Agent Identity

## Why ERC-4337 for Agents

Traditional externally owned accounts (EOAs) are designed for human users with a single private key. Autonomous AI agents have fundamentally different requirements:

- **Programmable permissions**: An agent needs fine-grained control, not just "sign or don't sign"
- **Delegation with expiry**: Sub-agents and services need time-bounded, scoped access
- **Batched operations**: Agents often need to execute multiple actions atomically
- **Gas sponsorship**: Agent operators need to fund gas without sharing keys
- **Recovery**: If an agent's key is compromised, the owner must be able to deactivate it

ERC-4337 account abstraction on Arbitrum provides all of these natively. Each agent identity is a smart contract account with programmable validation logic.

## Identity Model

```
+------------------+
|  Agent Account   |
|  (ERC-4337 SA)   |
+--------+---------+
         |
  +------+------+------+
  |      |      |      |
  v      v      v      v
Sub-   Service  Auditor  ...
Agent  Provider
```

Each agent has:
- **agentId**: Unique bytes32 identifier (keccak256 of public key or deterministic salt)
- **owner**: The EOA or multisig that controls the agent account
- **metadataHash**: IPFS/Arweave pointer to agent capabilities, description, and configuration
- **reputationScore**: On-chain score updated based on workflow settlement outcomes
- **active**: Boolean flag for deactivation

## Delegation System

Delegations allow agents to grant scoped permissions to other addresses:

```solidity
struct Delegation {
    address delegate;       // Who receives the permission
    bytes32 permissionScope; // What they can do (encoded scope)
    uint256 validUntil;     // When the delegation expires
    bool revoked;           // Whether it's been revoked early
}
```

Permission scopes are bytes32-encoded identifiers that downstream contracts can check. Examples:
- `keccak256("execute")` - Can execute workflows on behalf of the agent
- `keccak256("read-memory")` - Can read the agent's memory graph
- `keccak256("manage-sub-agents")` - Can create/revoke sub-agent delegations

## Reputation Tracking

Reputation is updated based on verifiable on-chain activity:
- Successfully settled workflows increase score
- Attestation submission rate
- Dispute outcomes (when dispute resolution is implemented)

The reputation score is stored on-chain in the AgentProfile struct and can be queried by other contracts before accepting workflow requests.

## MVP Scope

**Implemented:**
- Agent registration with metadata
- Delegation creation with scoped permissions and expiry
- Delegation revocation
- Delegation validity checks
- Agent deactivation
- Owner-based access control
- Reputation score storage

**Future work:**
- ERC-4337 UserOperation validation integration
- Multi-sig owner support
- Delegation chain depth limits
- On-chain reputation calculation formula
- Agent metadata schema standardization
