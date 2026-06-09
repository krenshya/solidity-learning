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

    // ----- Reentrancy lock (used by the nonReentrant modifier) -----
    bool private locked;

    // ----- Events: the contract's notifications to the outside world -----
    event PaymentReceived(address indexed buyer, uint256 amount);
    event ItemShipped(address indexed seller);
    event DeliveryConfirmed(address indexed buyer);
    event FundsReleased(address indexed seller, uint256 amount);
    event BuyerRefunded(address indexed buyer, uint256 amount);
    event DisputeRaised(address indexed raisedBy);
    event DisputeResolved(address indexed arbiter, bool paidSeller);

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

    // ----- Modifiers: reusable checks that guard the functions below -----
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this");
        _;
    }

    modifier inState(State expected) {
        require(currentState == expected, "Invalid state for this action");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrant call blocked");
        locked = true;
        _;
        locked = false;
    }

    // ----- Step 1: buyer deposits the exact price, locking funds in escrow -----
    function deposit() external payable onlyBuyer inState(State.AwaitingPayment) {
        require(msg.value == price, "Must send the exact price");

        currentState = State.Secured;
        emit PaymentReceived(msg.sender, msg.value);
    }

    // ----- Step 2: seller marks the item as shipped -----
    function markShipped() external onlySeller inState(State.Secured) {
        currentState = State.Shipped;
        emit ItemShipped(msg.sender);
    }

    // ----- Step 3: buyer confirms they received the item -----
    function confirmDelivered() external onlyBuyer inState(State.Shipped) {
        currentState = State.Delivered;
        emit DeliveryConfirmed(msg.sender);
    }

    // ----- Step 4: seller claims the funds after delivery is confirmed -----
    function release() external onlySeller inState(State.Delivered) nonReentrant {
        // Effects first: mark the deal finished BEFORE sending any ETH.
        currentState = State.Released;

        // Interaction last: send the locked price to the seller using call.
        (bool success, ) = seller.call{value: price}("");
        require(success, "ETH transfer to seller failed");

        emit FundsReleased(seller, price);
    }

    // ----- Branch: seller voluntarily refunds the buyer (before delivery is confirmed) -----
    function refundBuyer() external onlySeller nonReentrant {
        require(
            currentState == State.Secured || currentState == State.Shipped,
            "Can only refund before delivery is confirmed"
        );

        // Effects first: mark the deal refunded BEFORE sending any ETH.
        currentState = State.Refunded;

        // Interaction last: send the locked price back to the buyer using call.
        (bool success, ) = buyer.call{value: price}("");
        require(success, "ETH refund to buyer failed");

        emit BuyerRefunded(buyer, price);
    }

    // ----- Branch: buyer or seller flags a problem, freezing the deal for the arbiter -----
    function raiseDispute() external {
        require(
            msg.sender == buyer || msg.sender == seller,
            "Only buyer or seller can dispute"
        );
        require(
            currentState == State.Secured ||
            currentState == State.Shipped ||
            currentState == State.Delivered,
            "Can only dispute an active deal"
        );

        currentState = State.Disputed;
        emit DisputeRaised(msg.sender);
    }

    // ----- Finale: arbiter resolves the dispute, sending funds to one side -----
    function resolveDispute(bool payToSeller) external onlyArbiter inState(State.Disputed) nonReentrant {
        address recipient;

        // Effects first: set the final state based on the arbiter's decision.
        if (payToSeller) {
            currentState = State.Released;
            recipient = seller;
        } else {
            currentState = State.Refunded;
            recipient = buyer;
        }

        // Interaction last: send the locked price to whoever the arbiter chose.
        (bool success, ) = recipient.call{value: price}("");
        require(success, "ETH transfer failed");

        emit DisputeResolved(msg.sender, payToSeller);
    }
}
