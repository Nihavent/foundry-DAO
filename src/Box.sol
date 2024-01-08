//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private s_number;

    event ValueChanged(uint256 value);

    constructor(address owner) Ownable(owner) {}

    function storeNumber(uint256 value) public onlyOwner {
        s_number = value;
        emit ValueChanged(value);
    }

    function getNumber() external view returns (uint256) {
        return s_number;
    }
}
