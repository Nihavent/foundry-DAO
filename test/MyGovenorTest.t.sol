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

    address public user = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    uint256 public constant MIN_DELAY = 3600; // 1 hour delay after vote passes

    address[] proposers;
    address[] executors;
    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    function setUp() public {
        //(1)
        timelock = new MyTimeLock(MIN_DELAY, proposers, executors, address(this));
        //(2)
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();
        timelock.revokeRole(adminRole, address(this));

        box = new Box(address(timelock));
    }

    // function setUp() public {
    //     govToken = new GovToken();
    //     govToken.mint(user, INITIAL_SUPPLY);    

    //     vm.startPrank(user);
    //     govToken.delegate(user);

    //     timelock = new TimeLock(MIN_DELAY, proposers, executors);

    //     governor = new MyGovernor(govToken, timelock);

    //     bytes32 proposerRole = timelock.PROPOSER_ROLE();
    //     bytes32 executorRole = timelock.EXECUTOR_ROLE();
    //     bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

    //     timelock.grantRole(proposerRole, address(governor));
    //     timelock.grantRole(executorRole, address(governor));
    //     timelock.revokeRole(adminRole, user); // Revokes admin role from user  - this was just to deploy the contract

    //     vm.stopPrank();

    //     box = new Box();
    //     box.transferOwnership(address(timelock));
    // }


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
    }

}