// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VaultManager {
    mapping(address => uint256) public balances;
    uint256 public totalVaultValue;

    bool public paused;
    address[] public owners;
    mapping(address => bool) public isOwner;

    error NotOwner();
    error Paused();
    error InsufficientBalance();
    error AddressZero();
    error NoOwners();

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);

    modifier onlyOwner() {
        require(isOwner[msg.sender], NotOwner());
        _;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(!paused, Paused());
        require(balances[msg.sender] >= amount, InsufficientBalance());

        balances[msg.sender] -= amount;
        totalVaultValue -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function emergencyWithdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        totalVaultValue = 0;
    }
}
