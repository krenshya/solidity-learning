// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint256 public count;
    address public owner;

    event Incremented(uint256 newCount);

    constructor() {
        owner = msg.sender;
    }

    function increment() public {
        count += 1;
        emit Incremented(count);
    }

    function reset() public {
        require(msg.sender == owner, "Only owner can reset");
        count = 0;
    }
}