// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title EscrowDemo
/// @author krenshya
/// @notice A learning escrow: one buyer, one seller, one arbiter, one purchase.
/// @dev Not audited. Learning and portfolio use only. Do not use with real value beyond testing.
contract EscrowDemo {
    // ----- Roles -----
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;

    // ----- Deal terms -----
    uint256 public immutable price;

    // ----- The state machine -----
    enum State {
        AwaitingPayment, // 0  deployed, buyer has not paid yet
        Secured,         // 1  buyer paid, ETH locked in this contract
        Shipped,         // 2  seller marked it shipped
        Delivered,       // 3  buyer confirmed they received it
        Released,        // 4  ETH sent to seller (final)
        Refunded,        // 5  ETH returned to buyer (final)
        Disputed         // 6  dispute raised, waiting for the arbiter
    }

    State public currentState;

    // ----- Constructor: runs once, at deployment -----
    constructor(address _seller, address _arbiter, uint256 _price) {
        require(_seller != address(0), "Seller cannot be zero address");
        require(_arbiter != address(0), "Arbiter cannot be zero address");
        require(_price > 0, "Price must be greater than zero");
        require(_seller != msg.sender, "Buyer and seller must differ");
        require(_arbiter != msg.sender, "Arbiter cannot be the buyer");
        require(_arbiter != _seller, "Arbiter cannot be the seller");

        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        price = _price;
    }
}