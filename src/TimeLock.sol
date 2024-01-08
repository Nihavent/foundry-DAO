// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";


contract MyTimeLock is TimelockController {

    // minDelay is how long you have to wait before executing
    // proposers are the addresses that can propose a vote
    // executors are the addresses that can execute a vote
    constructor(
        uint256 minDelay, 
        address[] memory proposers, 
        address[] memory executors, 
        address admin
    ) TimelockController(minDelay, proposers, executors, admin)
    {}
    
}




