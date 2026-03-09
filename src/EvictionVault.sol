// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "./VaultManager.sol";
// import "./TransactionManager.sol";
// import "./ClaimManager.sol";

// contract EvictionVault is VaultManager, TransactionManager, ClaimManager {
//     error NoOwners();
//     error AddressZero();

//     constructor(address[] memory _owners, uint256 _threshold) payable {
//         require(_owners.length > 0, NoOwners());
//         threshold = _threshold;

//         for (uint i = 0; i < _owners.length; i++) {
//             address o = _owners[i];
//             require(o != address(0), AddressZero());
//             isOwner[o] = true;
//             owners.push(o);
//         }
//         totalVaultValue = msg.value;
//     }

//     function pause() external onlyOwner {
//         paused = true;
//     }

//     function unpause() external onlyOwner {
//         paused = false;
//     }
// }