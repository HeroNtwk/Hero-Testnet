// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/WorkflowSettlement.sol";

contract WorkflowSettlementTest is Test {
    WorkflowSettlement public settlement;
    bytes32 public requesterId = keccak256("requester-001");
    bytes32 public executorId = keccak256("executor-001");
    bytes32 public taskHash = keccak256("analyze-portfolio");
    bytes32 public inputCommitment = keccak256("encrypted-input");
    address payable public executorOwner = payable(address(0x3));

    function setUp() public {
        settlement = new WorkflowSettlement();
        vm.deal(address(this), 10 ether);
    }

    function testRequestWorkflow() public {
        uint256 workflowId = settlement.requestWorkflow{value: 1 ether}(
            requesterId, taskHash, inputCommitment
        );

        assertEq(workflowId, 0);

        WorkflowSettlement.Workflow memory wf = settlement.getWorkflow(0);
        assertEq(wf.requesterId, requesterId);
        assertEq(wf.taskHash, taskHash);
        assertEq(wf.escrowAmount, 1 ether);
        assertEq(uint256(wf.status), uint256(WorkflowSettlement.WorkflowStatus.Requested));
    }

    function testFullWorkflowLifecycle() public {
        // 1. Request
        uint256 workflowId = settlement.requestWorkflow{value: 1 ether}(
            requesterId, taskHash, inputCommitment
        );

        // 2. Assign executor
        settlement.assignExecutor(workflowId, executorId);
        WorkflowSettlement.Workflow memory wf = settlement.getWorkflow(workflowId);
        assertEq(uint256(wf.status), uint256(WorkflowSettlement.WorkflowStatus.Executing));
        assertEq(wf.executorId, executorId);

        // 3. Submit attestation
        bytes32 attestationHash = keccak256("zk-proof-hash");
        bytes32 outputCommitment = keccak256("encrypted-output");
        settlement.submitAttestation(workflowId, attestationHash, outputCommitment);
        wf = settlement.getWorkflow(workflowId);
        assertEq(uint256(wf.status), uint256(WorkflowSettlement.WorkflowStatus.Attested));

        // 4. Settle
        uint256 balanceBefore = executorOwner.balance;
        settlement.settleWorkflow(workflowId, executorOwner);
        wf = settlement.getWorkflow(workflowId);
        assertEq(uint256(wf.status), uint256(WorkflowSettlement.WorkflowStatus.Settled));
        assertEq(executorOwner.balance, balanceBefore + 1 ether);
    }

    function testCannotSettleWithoutAttestation() public {
        uint256 workflowId = settlement.requestWorkflow{value: 1 ether}(
            requesterId, taskHash, inputCommitment
        );

        vm.expectRevert("WorkflowSettlement: not attested");
        settlement.settleWorkflow(workflowId, executorOwner);
    }

    function testCannotAssignExecutorTwice() public {
        uint256 workflowId = settlement.requestWorkflow{value: 1 ether}(
            requesterId, taskHash, inputCommitment
        );

        settlement.assignExecutor(workflowId, executorId);

        vm.expectRevert("WorkflowSettlement: invalid status");
        settlement.assignExecutor(workflowId, keccak256("another-executor"));
    }

    function testRequiresEscrow() public {
        vm.expectRevert("WorkflowSettlement: escrow required");
        settlement.requestWorkflow{value: 0}(requesterId, taskHash, inputCommitment);
    }

    function testCancelWorkflow() public {
        address payable refundAddr = payable(address(0x4));
        uint256 workflowId = settlement.requestWorkflow{value: 1 ether}(
            requesterId, taskHash, inputCommitment
        );

        uint256 balanceBefore = refundAddr.balance;
        settlement.cancelWorkflow(workflowId, refundAddr);

        WorkflowSettlement.Workflow memory wf = settlement.getWorkflow(workflowId);
        assertEq(uint256(wf.status), uint256(WorkflowSettlement.WorkflowStatus.Cancelled));
        assertEq(refundAddr.balance, balanceBefore + 1 ether);
    }

    function testCannotCancelAfterExecution() public {
        uint256 workflowId = settlement.requestWorkflow{value: 1 ether}(
            requesterId, taskHash, inputCommitment
        );

        settlement.assignExecutor(workflowId, executorId);

        vm.expectRevert("WorkflowSettlement: cannot cancel");
        settlement.cancelWorkflow(workflowId, payable(address(0x4)));
    }

    function testWorkflowCount() public {
        settlement.requestWorkflow{value: 1 ether}(requesterId, taskHash, inputCommitment);
        settlement.requestWorkflow{value: 2 ether}(requesterId, keccak256("task-2"), inputCommitment);

        assertEq(settlement.workflowCount(), 2);
    }
}
