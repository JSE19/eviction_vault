// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TransactionManager {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    mapping(address => bool) public isOwner;
    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => Transaction) public transactions;

    uint256 public threshold;
    uint256 public txCount;
    bool public paused;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    error NotOwner();
    error Paused();
    error Executed();
    error AddressZero();
    error InsufficientBalance();

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], NotOwner());
        _;
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        require(!paused, Paused());
        require(_to != address(0), AddressZero());
        require(_value <= address(this).balance, InsufficientBalance());

        uint256 id = txCount++;
        transactions[id] = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });
        confirmed[id][msg.sender] = true;
        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external onlyOwner {
        require(!paused, Paused());
        
        Transaction storage txn = transactions[txId];
        require(!txn.executed, Executed());
        require(!confirmed[txId][msg.sender], "Already confirmed");

        confirmed[txId][msg.sender] = true;
        txn.confirmations++;

        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        require(!paused, Paused());
        
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold, "Insufficient confirmations");
        require(!txn.executed, Executed());
        require(block.timestamp >= txn.executionTime, "Timelock not elapsed");

        txn.executed = true;
        (bool s, ) = txn.to.call{value: txn.value}(txn.data);
        require(s, "Execution failed");

        emit Execution(txId);
    }
}