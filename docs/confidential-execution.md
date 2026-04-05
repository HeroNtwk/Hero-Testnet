# Confidential Execution

## Why FHE via Fhenix CoFHE

When autonomous agents process sensitive data (financial portfolios, medical records, proprietary business logic), the computation itself must be confidential. Several approaches exist:

| Approach | Trust Assumption | Quantum Safety | Arbitrum Native |
|----------|-----------------|----------------|-----------------|
| TEEs (SGX/TDX) | Hardware manufacturer | No | No |
| MPC | Honest majority | Varies | No |
| FHE (Fhenix CoFHE) | Mathematical (lattice) | Yes | Yes |

Hero uses Fhenix CoFHE because:

1. **No hardware trust assumptions**: FHE security is based on the hardness of lattice problems, not on trusting Intel or AMD hardware
2. **Quantum-resistant**: Lattice-based cryptography is believed to be secure against quantum computers
3. **Native Arbitrum integration**: Fhenix CoFHE is already deployed on Arbitrum, backed by a strategic investment from Tandem (Offchain Labs' venture arm)
4. **Minimal Solidity changes**: Developers use standard Solidity with Fhenix encrypted type wrappers

## Integration Flow

```
1. Agent encrypts task parameters
   +--------+
   | Agent  | ---> encrypt(input) ---> euint256
   +--------+

2. Hero contract receives encrypted input
   +----------------+
   | Workflow       | ---> stores inputCommitment
   | Settlement     |
   +----------------+

3. Fhenix CoFHE processes encrypted computation
   +----------------+
   | Fhenix CoFHE   | ---> FHE.add(ea, eb) ---> encrypted result
   | Coprocessor    |
   +----------------+

4. Result committed on-chain
   +----------------+
   | Hero Contract  | ---> attestationHash + outputCommitment
   +----------------+

5. Settlement on Arbitrum
   +----------------+
   | Arbitrum       | ---> escrow release
   +----------------+
```

## Conceptual Integration Example

```solidity
// NOTE: This is a conceptual example showing the integration pattern.
// Actual implementation requires the Fhenix SDK and deployed CoFHE contracts.

import "fhenix/FHE.sol";

contract ConfidentialWorkflow {
    // Encrypted task parameters stay encrypted throughout processing
    function processConfidentialTask(
        euint256 encryptedInput,
        bytes32 agentId
    ) public returns (bytes32 outputCommitment) {
        // Computation happens over encrypted data via CoFHE
        euint256 result = FHE.add(encryptedInput, FHE.asEuint256(1));

        // Only the agent with the decryption key can read the result
        // The contract never sees plaintext
        outputCommitment = keccak256(abi.encodePacked(result));
    }
}
```

## ZK Verification Layer

On top of confidential execution, Hero adds a ZK verification layer for defense-in-depth:

- **Execution attestation**: After CoFHE computation completes, a ZK proof attests that the computation followed the expected workflow steps
- **Input/output commitments**: Halo2/PLONK SNARKs prove the relationship between encrypted inputs and outputs without revealing either
- **Composable proofs**: Multiple workflow steps can be composed into a single proof for batch verification

This layered approach means:
- CoFHE ensures data stays encrypted during computation
- ZK proofs ensure the computation was performed correctly
- Arbitrum settlement ensures the economic incentives are enforced

## MVP Scope

**Phase 1:**
- WorkflowSettlement contract with attestation hash storage
- Input/output commitment fields in workflow struct
- Integration patterns documented for Fhenix CoFHE

**Phase 2:**
- Live Fhenix CoFHE integration on Arbitrum Sepolia
- Encrypted type handling in workflow contracts
- Basic ZK attestation verification

**Phase 3:**
- Full Halo2/PLONK proof generation and verification
- Composable multi-step workflow proofs
- Production CoFHE integration on Arbitrum One
