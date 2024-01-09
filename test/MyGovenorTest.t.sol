// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Box} from "../src/Box.sol";
import {MyTimeLock} from "../src/TimeLock.sol";
import {GovToken} from "../src/GovToken.sol";

contract MyGovenorTest is Test {
    MyGovernor governor;
    Box box;
    MyTimeLock timelock;
    GovToken govToken;

    address public constant VOTER = address(1);
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    uint256 public constant MIN_DELAY = 3600; // 1 hour delay after vote passes
    uint256 public constant VOTING_DELAY = 1;
    uint256 public constant VOTING_PERIOD = 50400;

    address[] proposers;
    address[] executors;
    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    function setUp() public {

        govToken = new GovToken();
        govToken.mint(VOTER, 100e18);

        vm.prank(VOTER);
        govToken.delegate(VOTER);

        timelock = new MyTimeLock(MIN_DELAY, proposers, executors, address(this));
        governor = new MyGovernor(govToken, timelock);
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, address(this));

        box = new Box(address(timelock));
    }


    function testCantUpdateBoxWithoutGovernor() public {
        vm.expectRevert();
        box.storeNumber(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 888;
        string memory description = "Store 888 in Box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("storeNumber(uint256)", valueToStore);
        
        values.push(0);
        calldatas.push(encodedFunctionCall);
        targets.push(address(box));

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // View the state of the proposal
        console.log("Proposal State: ", uint256(governor.state(proposalId)));
        console.log("governor.proposalSnapshot(proposalId): ", governor.proposalSnapshot(proposalId));
        console.log("governor.proposalThreshold(): ", governor.proposalThreshold());

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        // View the state of the proposal - should now be active
        console.log("Proposal State: ", uint256(governor.state(proposalId)));
        console.log("governor.proposalSnapshot(proposalId): ", governor.proposalSnapshot(proposalId));

        // 2. Vote on the proposal
        string memory reason = "Because I said so";
         // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;

        vm.prank(VOTER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        console.log("Vote Cast");

        //speed up voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State: ", uint256(governor.state(proposalId)));
        console.log("governor.proposalSnapshot(proposalId): ", governor.proposalSnapshot(proposalId));
        console.log("governor.proposalDeadline(proposalId): ", governor.proposalDeadline(proposalId));


        // 3. Queue the tx 
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        console.log("Proposal State: ", uint256(governor.state(proposalId)));
        console.log("governor.proposalSnapshot(proposalId): ", governor.proposalSnapshot(proposalId));


        // 4. Execute tx
        governor.execute(targets, values, calldatas, descriptionHash);

        assert(box.getNumber() == valueToStore);
    }

}