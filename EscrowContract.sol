//SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Escrow is ReentrancyGuard {

    address public buyer;
    address public seller;
    address public arbiter;

    uint256 public constant amount = 2 ether;
    uint256 public immutable arbitrationPeriod;

    enum State{
        INITIATED,
        PAYMENT_DEPOSITED,
        DELIVERED,
        NOT_DELIVERED,
        RELEASED,
        DESTROYED
    }

    State public currentState;

    modifier onlyArbiter(){
        if(msg.sender!=arbiter)
        revert();
        _;
    }

    modifier onlyBuyer(){
        if(msg.sender!=buyer)
        revert();
        _;
    }

    modifier inState(State state){
        if(currentState!=state)
        revert();
        _;
    }

    constructor(address _buyer, address _seller){
        arbiter = msg.sender;
        buyer = _buyer;
        seller = _seller;
        arbitrationPeriod =  block.timestamp + 3 days;

    }

    function deposit() public payable onlyBuyer inState(State.INITIATED){
        if(msg.value!=amount)
        revert();
        currentState = State.PAYMENT_DEPOSITED;
    }

    function confirmDelivery() public onlyArbiter inState(State.PAYMENT_DEPOSITED){
        if(block.timestamp<=arbitrationPeriod){
            currentState = State.DELIVERED;
        }
        else{
            currentState = State.NOT_DELIVERED;
        }
    }

    function sellerPayment() public payable onlyArbiter inState(State.DELIVERED) nonReentrant{
        (bool sent,) = seller.call{value:amount}("");
        if(!sent)
        revert();
        currentState = State.RELEASED;
    }

    function refundBuyer() public payable onlyArbiter inState(State.NOT_DELIVERED) nonReentrant{
        (bool sent,) = buyer.call{value:amount}("");
        if(!sent)
        revert();
        currentState = State.DESTROYED;
    }
}