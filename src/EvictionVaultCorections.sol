// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EvictionVault {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public threshold;

    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => Transaction) public transactions;

    uint256 public txCount;

    mapping(address => uint256) public balances;

    bytes32 public merkleRoot;

    mapping(address => bool) public claimed;

    mapping(bytes32 => bool) public usedHashes;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    uint256 public totalVaultValue;

    bool public paused;

    error NotOwner();
    error NoOwners();
    error AddressZero();
    error Paused();
    error Claimed();
    error InsufficientBalance();
    error Executed();
    error Confirmed();
    error NotEnoughConfirmation();
    error Failed();

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);
    event MerkleRootSet(bytes32 indexed newRoot);
    event Claim(address indexed claimant, uint256 amount);

    constructor(address[] memory _owners, uint256 _threshold) payable {
        require(_owners.length > 0, NoOwners());
        threshold = _threshold;

        for (uint i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), AddressZero());
            isOwner[o] = true;
            owners.push(o);
        }
        totalVaultValue = msg.value;
    }

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

    function withdraw(uint256 amount) external onlyOwner returns(bool) {
        require(!paused, Paused());
        require(balances[msg.sender] >= amount, InsufficientBalance());
        balances[msg.sender] -= amount;
        totalVaultValue -= amount;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, Failed());
        emit Withdrawal(msg.sender, amount);
        return success;
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external {
        require(!paused, Paused());
        require(isOwner[msg.sender], NotOwner());
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

    function confirmTransaction(uint256 txId) external {
        require(!paused, Paused());
        require(isOwner[msg.sender], NotOwner());
        Transaction storage txn = transactions[txId];
        require(!txn.executed, Executed());
        require(!confirmed[txId][msg.sender], Confirmed());
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold, NotEnoughConfirmation());
        require(!txn.executed, Executed());
        require(!paused, Paused());
        require(block.timestamp >= txn.executionTime);
        txn.executed = true;
        (bool s, ) = txn.to.call{value: txn.value}(txn.data);
        require(s,Failed());
        emit Execution(txId);
    }

    function setMerkleRoot(bytes32 root) external  {
        require(isOwner[msg.sender], NotOwner());
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount) external returns (bool){
        require(!paused, Paused());
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 computed = MerkleProof.processProof(proof, leaf);
        require(computed == merkleRoot);
        require(!claimed[msg.sender], Claimed());
        claimed[msg.sender] = true;
        totalVaultValue -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, Failed());
        emit Claim(msg.sender, amount);
        return success;
    }

    function verifySignature(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (bool) {
        return ECDSA.recover(messageHash, signature) == signer;
        //return MerkleProof.recover(messageHash, signature) == signer;
    }

    function emergencyWithdrawAll() external onlyOwner returns(bool) {
        
        uint256 amount = address(this).balance;
        totalVaultValue = 0;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, Failed());
        return success;
    }

    function pause() external {
        require(isOwner[msg.sender], NotOwner());
        paused = true;
    }

    function unpause() external {
        require(isOwner[msg.sender], NotOwner());
        paused = false;
    }
}
