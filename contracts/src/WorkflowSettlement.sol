// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WorkflowSettlement
/// @notice Workflow lifecycle management: request -> execute -> attest -> settle
/// @dev Handles escrow, attestation verification, and settlement on Arbitrum
contract WorkflowSettlement {
    enum WorkflowStatus {
        Requested,
        Executing,
        Attested,
        Settled,
        Disputed,
        Cancelled
    }

    struct Workflow {
        bytes32 requesterId;
        bytes32 executorId;
        bytes32 taskHash;
        bytes32 inputCommitment;
        bytes32 outputCommitment;
        bytes32 attestationHash;
        uint256 escrowAmount;
        uint256 createdAt;
        uint256 settledAt;
        WorkflowStatus status;
    }

    uint256 public workflowCount;
    mapping(uint256 => Workflow) public workflows;
    mapping(bytes32 => address) public agentOwners;

    event WorkflowRequested(uint256 indexed workflowId, bytes32 indexed requesterId, bytes32 taskHash, uint256 escrowAmount);
    event WorkflowExecutorAssigned(uint256 indexed workflowId, bytes32 indexed executorId);
    event WorkflowAttested(uint256 indexed workflowId, bytes32 attestationHash, bytes32 outputCommitment);
    event WorkflowSettled(uint256 indexed workflowId, uint256 amount);
    event WorkflowDisputed(uint256 indexed workflowId);
    event WorkflowCancelled(uint256 indexed workflowId);

    /// @notice Request a new workflow with escrow
    /// @param requesterId The agent requesting the workflow
    /// @param taskHash Hash describing the task to be performed
    /// @param inputCommitment Commitment to the encrypted input data
    /// @return workflowId The ID of the created workflow
    function requestWorkflow(
        bytes32 requesterId,
        bytes32 taskHash,
        bytes32 inputCommitment
    ) external payable returns (uint256 workflowId) {
        require(msg.value > 0, "WorkflowSettlement: escrow required");
        require(taskHash != bytes32(0), "WorkflowSettlement: empty task hash");

        // Register caller as agent owner for access control
        // TODO: Replace with AgentRegistry lookup once integrated
        if (agentOwners[requesterId] == address(0)) {
            agentOwners[requesterId] = msg.sender;
        }
        require(agentOwners[requesterId] == msg.sender, "WorkflowSettlement: not agent owner");

        workflowId = workflowCount;
        workflows[workflowId] = Workflow({
            requesterId: requesterId,
            executorId: bytes32(0),
            taskHash: taskHash,
            inputCommitment: inputCommitment,
            outputCommitment: bytes32(0),
            attestationHash: bytes32(0),
            escrowAmount: msg.value,
            createdAt: block.timestamp,
            settledAt: 0,
            status: WorkflowStatus.Requested
        });

        workflowCount++;
        emit WorkflowRequested(workflowId, requesterId, taskHash, msg.value);
    }

    /// @notice Assign an executor agent to a workflow
    /// @param workflowId The workflow to assign
    /// @param executorId The agent that will execute the task
    function assignExecutor(uint256 workflowId, bytes32 executorId) external {
        Workflow storage wf = workflows[workflowId];
        require(wf.status == WorkflowStatus.Requested, "WorkflowSettlement: invalid status");
        require(executorId != bytes32(0), "WorkflowSettlement: invalid executor");
        require(agentOwners[wf.requesterId] == msg.sender, "WorkflowSettlement: only requester can assign");

        wf.executorId = executorId;
        wf.status = WorkflowStatus.Executing;
        emit WorkflowExecutorAssigned(workflowId, executorId);
    }

    /// @notice Submit an attestation after workflow execution
    /// @param workflowId The workflow that was executed
    /// @param attestationHash Hash of the execution attestation (ZK proof or CoFHE result)
    /// @param outputCommitment Commitment to the encrypted output data
    function submitAttestation(
        uint256 workflowId,
        bytes32 attestationHash,
        bytes32 outputCommitment
    ) external {
        Workflow storage wf = workflows[workflowId];
        require(wf.status == WorkflowStatus.Executing, "WorkflowSettlement: invalid status");
        require(attestationHash != bytes32(0), "WorkflowSettlement: empty attestation");
        // TODO: Restrict to executor's owner via AgentRegistry once integrated

        wf.attestationHash = attestationHash;
        wf.outputCommitment = outputCommitment;
        wf.status = WorkflowStatus.Attested;
        emit WorkflowAttested(workflowId, attestationHash, outputCommitment);
    }

    /// @notice Settle a workflow, releasing escrow to the executor's owner
    /// @param workflowId The workflow to settle
    /// @param executorOwner The address to receive the escrow payment
    function settleWorkflow(uint256 workflowId, address payable executorOwner) external {
        Workflow storage wf = workflows[workflowId];
        require(wf.status == WorkflowStatus.Attested, "WorkflowSettlement: not attested");
        require(
            agentOwners[wf.requesterId] == msg.sender || agentOwners[wf.executorId] == msg.sender,
            "WorkflowSettlement: unauthorized caller"
        );

        uint256 amount = wf.escrowAmount;
        wf.status = WorkflowStatus.Settled;
        wf.settledAt = block.timestamp;

        (bool success, ) = executorOwner.call{value: amount}("");
        require(success, "WorkflowSettlement: transfer failed");

        emit WorkflowSettled(workflowId, amount);
    }

    /// @notice Get full workflow details
    /// @param workflowId The workflow to query
    /// @return The Workflow struct
    function getWorkflow(uint256 workflowId) external view returns (Workflow memory) {
        require(workflowId < workflowCount, "WorkflowSettlement: workflow does not exist");
        return workflows[workflowId];
    }

    /// @notice Cancel a workflow and refund escrow (only if not yet executing)
    /// @param workflowId The workflow to cancel
    /// @param refundAddress The address to receive the refund
    function cancelWorkflow(uint256 workflowId, address payable refundAddress) external {
        Workflow storage wf = workflows[workflowId];
        require(wf.status == WorkflowStatus.Requested, "WorkflowSettlement: cannot cancel");
        require(agentOwners[wf.requesterId] == msg.sender, "WorkflowSettlement: only requester can cancel");

        uint256 amount = wf.escrowAmount;
        wf.status = WorkflowStatus.Cancelled;

        (bool success, ) = refundAddress.call{value: amount}("");
        require(success, "WorkflowSettlement: refund failed");

        emit WorkflowCancelled(workflowId);
    }
}
