// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AgentRegistry
/// @notice Registry for autonomous agent identities on Hero Network
/// @dev Manages agent profiles, delegations, and reputation tracking
contract AgentRegistry {
    struct AgentProfile {
        address owner;
        bytes32 metadataHash;
        uint256 registeredAt;
        uint256 reputationScore;
        bool active;
    }

    struct Delegation {
        address delegate;
        bytes32 permissionScope;
        uint256 validUntil;
        bool revoked;
    }

    mapping(bytes32 => AgentProfile) public agents;
    mapping(bytes32 => uint256) public delegationCount;
    mapping(bytes32 => mapping(uint256 => Delegation)) public delegations;
    mapping(address => bytes32[]) public ownerAgents;

    event AgentRegistered(bytes32 indexed agentId, address indexed owner, bytes32 metadataHash);
    event DelegationCreated(bytes32 indexed agentId, uint256 indexed delegationId, address delegate, bytes32 permissionScope, uint256 validUntil);
    event DelegationRevoked(bytes32 indexed agentId, uint256 indexed delegationId);
    event ReputationUpdated(bytes32 indexed agentId, uint256 newScore);
    event AgentDeactivated(bytes32 indexed agentId);

    modifier onlyAgentOwner(bytes32 agentId) {
        require(agents[agentId].owner == msg.sender, "AgentRegistry: caller is not agent owner");
        _;
    }

    modifier agentExists(bytes32 agentId) {
        require(agents[agentId].registeredAt != 0, "AgentRegistry: agent does not exist");
        _;
    }

    /// @notice Register a new autonomous agent
    /// @param agentId Unique identifier for the agent (e.g. keccak256 of public key)
    /// @param metadataHash IPFS or Arweave hash pointing to agent metadata
    function registerAgent(bytes32 agentId, bytes32 metadataHash) external {
        require(agents[agentId].registeredAt == 0, "AgentRegistry: agent already registered");

        agents[agentId] = AgentProfile({
            owner: msg.sender,
            metadataHash: metadataHash,
            registeredAt: block.timestamp,
            reputationScore: 0,
            active: true
        });

        ownerAgents[msg.sender].push(agentId);
        emit AgentRegistered(agentId, msg.sender, metadataHash);
    }

    /// @notice Create a delegation granting another address scoped permissions
    /// @param agentId The agent granting the delegation
    /// @param delegate Address receiving delegated permissions
    /// @param permissionScope Bytes32-encoded scope of what the delegate can do
    /// @param validUntil Unix timestamp when the delegation expires
    function createDelegation(
        bytes32 agentId,
        address delegate,
        bytes32 permissionScope,
        uint256 validUntil
    ) external onlyAgentOwner(agentId) agentExists(agentId) returns (uint256) {
        require(validUntil > block.timestamp, "AgentRegistry: delegation already expired");

        uint256 delegationId = delegationCount[agentId];
        delegations[agentId][delegationId] = Delegation({
            delegate: delegate,
            permissionScope: permissionScope,
            validUntil: validUntil,
            revoked: false
        });

        delegationCount[agentId]++;
        emit DelegationCreated(agentId, delegationId, delegate, permissionScope, validUntil);
        return delegationId;
    }

    /// @notice Revoke an existing delegation
    /// @param agentId The agent that owns the delegation
    /// @param delegationId The delegation to revoke
    function revokeDelegation(bytes32 agentId, uint256 delegationId) external onlyAgentOwner(agentId) agentExists(agentId) {
        require(!delegations[agentId][delegationId].revoked, "AgentRegistry: delegation already revoked");
        delegations[agentId][delegationId].revoked = true;
        emit DelegationRevoked(agentId, delegationId);
    }

    /// @notice Check if a delegation is currently valid
    /// @param agentId The agent that owns the delegation
    /// @param delegationId The delegation to check
    /// @return valid True if the delegation is active and not expired
    function isDelegationValid(bytes32 agentId, uint256 delegationId) external view agentExists(agentId) returns (bool valid) {
        Delegation storage d = delegations[agentId][delegationId];
        return !d.revoked && d.validUntil > block.timestamp && d.delegate != address(0);
    }

    /// @notice Deactivate an agent, preventing further operations
    /// @param agentId The agent to deactivate
    function deactivateAgent(bytes32 agentId) external onlyAgentOwner(agentId) agentExists(agentId) {
        require(agents[agentId].active, "AgentRegistry: agent already inactive");
        agents[agentId].active = false;
        emit AgentDeactivated(agentId);
    }

    /// @notice Update an agent's reputation score
    /// @dev TODO: restrict to authorized callers (e.g. WorkflowSettlement)
    /// @param agentId The agent to update
    /// @param newScore The new reputation score
    function updateReputation(bytes32 agentId, uint256 newScore) external agentExists(agentId) {
        // TODO: Add access control - only WorkflowSettlement should call this
        agents[agentId].reputationScore = newScore;
        emit ReputationUpdated(agentId, newScore);
    }

    /// @notice Get all agent IDs owned by an address
    /// @param owner The owner address
    /// @return Array of agent IDs
    function getAgentsByOwner(address owner) external view returns (bytes32[] memory) {
        return ownerAgents[owner];
    }
}