// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// contract ClaimManager {
//     bytes32 public merkleRoot;
//     mapping(address => bool) public claimed;
//     bool public paused;
//     mapping(address => bool) public isOwner;
//     uint256 public totalVaultValue;

//     error NotOwner();
//     error Paused();
//     error Claimed();

//     event MerkleRootSet(bytes32 indexed newRoot);
//     event Claim(address indexed claimant, uint256 amount);

//     modifier onlyOwner() {
//         require(isOwner[msg.sender], NotOwner());
//         _;
//     }

//     function setMerkleRoot(bytes32 root) external onlyOwner {
//         merkleRoot = root;
//         emit MerkleRootSet(root);
//     }

//     function claim(bytes32[] calldata proof, uint256 amount) external {
//         require(!paused, Paused());
        
//         bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
//         bytes32 computed = MerkleProof.processProof(proof, leaf);
//         require(computed == merkleRoot, "Invalid proof");
//         require(!claimed[msg.sender], Claimed());

//         claimed[msg.sender] = true;
//         totalVaultValue -= amount;

//         (bool success, ) = payable(msg.sender).call{value: amount}("");
//         require(success, "Transfer failed");

//         emit Claim(msg.sender, amount);
//     }

//     function verifySignature(
//         address signer,
//         bytes32 messageHash,
//         bytes memory signature
//     ) external pure returns (bool) {
//         return ECDSA.recover(messageHash, signature) == signer;
//     }
// }