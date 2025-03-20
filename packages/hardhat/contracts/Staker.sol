// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    uint256 public deadline = block.timestamp + 72 hours;
    uint256 public constant threshold = 1 ether;
    bool public openForWithdraw;
    mapping(address => uint256) public balances;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    event Stake(address, uint256);

    error UnAuthorized();
    error InvalidAmount();
    error DeadlineNotReached();
    error AlreadyCompleted();
    error NotOpenForWithdraw();

    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Already completed");
        _;
    }

    function stake() public payable returns (bool) {
        if(msg.sender == address(0)) revert UnAuthorized();
        if(msg.value <= 0) revert InvalidAmount();
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
        return true;
    }

    function execute() public notCompleted {
        if(msg.sender == address(0)) revert UnAuthorized();
        if(exampleExternalContract.completed()) revert AlreadyCompleted();
        if(deadline >= block.timestamp) revert DeadlineNotReached();
        if(address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else if(address(this).balance < threshold) {
            openForWithdraw = true;
        }
    }

    function withdraw() public notCompleted {
        if(msg.sender == address(0)) revert UnAuthorized();
        if(openForWithdraw == false) revert NotOpenForWithdraw();
        uint256 _amount = balances[msg.sender];
        if(_amount <= 0) revert InvalidAmount();
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(_amount);
    }

    function timeLeft() public view returns (uint256) {
        if(block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    receive() external payable {
        stake();

    }
    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    // Add the `receive()` special function that receives eth and calls stake()
}
