// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/src/AgentRegistry.sol";
import "../contracts/src/MemoryCommitment.sol";
import "../contracts/src/WorkflowSettlement.sol";

/// @title Deploy
/// @notice Deployment script for Hero Network contracts on Arbitrum Sepolia
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        AgentRegistry registry = new AgentRegistry();
        console.log("AgentRegistry deployed at:", address(registry));

        MemoryCommitment memory_ = new MemoryCommitment();
        console.log("MemoryCommitment deployed at:", address(memory_));

        WorkflowSettlement settlement = new WorkflowSettlement();
        console.log("WorkflowSettlement deployed at:", address(settlement));

        vm.stopBroadcast();
    }
}
