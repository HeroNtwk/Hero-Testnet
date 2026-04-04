// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AgentRegistry.sol";

contract AgentRegistryTest is Test {
    AgentRegistry public registry;
    address public alice = address(0x1);
    address public bob = address(0x2);
    bytes32 public agentId = keccak256("agent-001");
    bytes32 public metadataHash = keccak256("ipfs://metadata");

    function setUp() public {
        registry = new AgentRegistry();
    }

    function testRegisterAgent() public {
        vm.prank(alice);
        registry.registerAgent(agentId, metadataHash);

        (address owner, bytes32 metadata, uint256 registeredAt, uint256 reputation, bool active) = registry.agents(agentId);
        assertEq(owner, alice);
        assertEq(metadata, metadataHash);
        assertGt(registeredAt, 0);
        assertEq(reputation, 0);
        assertTrue(active);
    }

    function testCannotRegisterDuplicate() public {
        vm.prank(alice);
        registry.registerAgent(agentId, metadataHash);

        vm.prank(bob);
        vm.expectRevert("AgentRegistry: agent already registered");
        registry.registerAgent(agentId, metadataHash);
    }

    function testCreateDelegation() public {
        vm.prank(alice);
        registry.registerAgent(agentId, metadataHash);

        vm.prank(alice);
        uint256 delegationId = registry.createDelegation(
            agentId,
            bob,
            keccak256("execute"),
            block.timestamp + 1 days
        );

        assertEq(delegationId, 0);

        (address delegate, bytes32 scope, uint256 validUntil, bool revoked) = registry.delegations(agentId, 0);
        assertEq(delegate, bob);
        assertEq(scope, keccak256("execute"));
        assertGt(validUntil, block.timestamp);
        assertFalse(revoked);
    }

    function testDelegationValidity() public {
        vm.prank(alice);
        registry.registerAgent(agentId, metadataHash);

        vm.prank(alice);
        uint256 delegationId = registry.createDelegation(
            agentId,
            bob,
            keccak256("execute"),
            block.timestamp + 1 days
        );

        assertTrue(registry.isDelegationValid(agentId, delegationId));
    }

    function testRevokeDelegation() public {
        vm.prank(alice);
        registry.registerAgent(agentId, metadataHash);

        vm.prank(alice);
        uint256 delegationId = registry.createDelegation(
            agentId,
            bob,
            keccak256("execute"),
            block.timestamp + 1 days
        );

        vm.prank(alice);
        registry.revokeDelegation(agentId, delegationId);

        assertFalse(registry.isDelegationValid(agentId, delegationId));
    }

    function testDeactivateAgent() public {
        vm.prank(alice);
        registry.registerAgent(agentId, metadataHash);

        vm.prank(alice);
        registry.deactivateAgent(agentId);

        (, , , , bool active) = registry.agents(agentId);
        assertFalse(active);
    }

    function testOnlyOwnerCanDeactivate() public {
        vm.prank(alice);
        registry.registerAgent(agentId, metadataHash);

        vm.prank(bob);
        vm.expectRevert("AgentRegistry: caller is not agent owner");
        registry.deactivateAgent(agentId);
    }

    function testGetAgentsByOwner() public {
        bytes32 agentId2 = keccak256("agent-002");

        vm.startPrank(alice);
        registry.registerAgent(agentId, metadataHash);
        registry.registerAgent(agentId2, keccak256("metadata-2"));
        vm.stopPrank();

        bytes32[] memory agentIds = registry.getAgentsByOwner(alice);
        assertEq(agentIds.length, 2);
        assertEq(agentIds[0], agentId);
        assertEq(agentIds[1], agentId2);
    }
}
