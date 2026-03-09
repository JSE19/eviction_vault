// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";

contract EvictionVaultPoolTest is Test {
    EvictionVault vault;
    address owner1;
    address owner2;
    address owner3;
    address user1;
    address user2;

    function setUp() public {
        owner1 = address(0x1);
        owner2 = address(0x2);
        owner3 = address(0x3);
        user1 = address(0x4);
        user2 = address(0x5);

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vault = new EvictionVault{value: 10 ether}(owners, 2);
    }

    function testDeposit() public {
        deal(user1, 5 ether);
        vm.prank(user1);
        
        vault.deposit{value: 1 ether}();
        
        assertEq(vault.balances(user1), 1 ether);
        assertEq(vault.totalVaultValue(), 11 ether);
    }

    function testReceiveETH() public {
        vm.prank(user1);
        vm.deal(user1, 5 ether);
        
        (bool success, ) = address(vault).call{value: 2 ether}("");
        require(success);
        
        assertEq(vault.balances(user1), 2 ether);
        assertEq(vault.totalVaultValue(), 12 ether);
    }

    function testSubmitTransaction() public {
        vm.prank(owner1);
        vault.submitTransaction(user1, 1 ether, "");
        
        (address to, uint256 value, , bool executed, uint256 confirmations, , ) = vault.transactions(0);
        assertEq(to, user1);
        assertEq(value, 1 ether);
        assertEq(executed, false);
        assertEq(confirmations, 1);
    }

    function testConfirmTransaction() public {
        vm.prank(owner1);
        vault.submitTransaction(user1, 1 ether, "");

        vm.prank(owner2);
        vault.confirmTransaction(0);

        (, , , , uint256 confirmations, , uint256 executionTime) = vault.transactions(0);
        assertEq(confirmations, 2);
        assertGt(executionTime, 0); 
    }

    function testExecuteTransaction() public {
        vm.prank(owner1);
        vault.submitTransaction(user1, 1 ether, "");

        vm.prank(owner2);
        vault.confirmTransaction(0);

        vm.warp(block.timestamp + 3601);

        vm.prank(owner3);
        vault.executeTransaction(0);

        (, , , bool executed, , , ) = vault.transactions(0);
        assertEq(executed, true);
    }

    function testPauseUnpause() public {
        assertEq(vault.paused(), false);

        vm.prank(owner1);
        vault.pause();
        assertEq(vault.paused(), true);

        vm.prank(owner1);
        vault.unpause();
        assertEq(vault.paused(), false);
    }

    function testEmergencyWithdrawAll() public {
        uint256 initialBalance = address(vault).balance;
        
        vm.prank(owner1);
        vault.emergencyWithdrawAll();

        assertEq(address(vault).balance, 0);
        assertEq(vault.totalVaultValue(), 0);
    }

    function testSetMerkleRoot() public {
        bytes32 root = keccak256(abi.encodePacked("test"));

        vm.prank(owner1);
        vault.setMerkleRoot(root);

        assertEq(vault.merkleRoot(), root);
    }

    function testWithdrawRevertWhenPaused() public {
        vm.prank(user1);
        vm.deal(user1, 5 ether);
        vault.deposit{value: 1 ether}();

        vm.prank(owner1);
        vault.pause();

        vm.prank(user1);
        vm.expectRevert();
        vault.withdraw(0.5 ether);
    }

    // function testSubmitTransactionRevertNonOwner() public {
    //     vm.prank(user1);
    //     vm.expectRevert();
    //     vault.submitTransaction(user1, 1 ether, "");
    // }

    // function testClaim() public {
    //     // Create a simple Merkle tree for testing
    //     bytes32 leaf1 = keccak256(abi.encodePacked(user1, uint256(1 ether)));
    //     bytes32 leaf2 = keccak256(abi.encodePacked(user2, uint256(2 ether)));
    //     bytes32[] memory leaves = new bytes32[](2);
    //     leaves[0] = leaf1;
    //     leaves[1] = leaf2;
        
    //     // For simplicity, assume root is hash of leaves[0] and leaves[1]
    //     bytes32 root = keccak256(abi.encodePacked(leaves[0], leaves[1]));
        
    //     vm.prank(owner1);
    //     vault.setMerkleRoot(root);
        
    //     // Proof for user1: since it's a simple tree, proof is [leaves[1]]
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = leaves[1];
        
    //     vm.prank(user1);
    //     vault.claim(proof, 1 ether);
        
    //     assertEq(vault.claimed(user1), true);
    //     assertEq(vault.totalVaultValue(), 9 ether); // 10 - 1
    // }

    // function testClaimRevertAlreadyClaimed() public {
    //     bytes32 leaf1 = keccak256(abi.encodePacked(user1, uint256(1 ether)));
    //     bytes32 leaf2 = keccak256(abi.encodePacked(user2, uint256(2 ether)));
    //     bytes32[] memory leaves = new bytes32[](2);
    //     leaves[0] = leaf1;
    //     leaves[1] = leaf2;
    //     bytes32 root = keccak256(abi.encodePacked(leaves[0], leaves[1]));
        
    //     vm.prank(owner1);
    //     vault.setMerkleRoot(root);
        
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = leaves[1];
        
    //     vm.prank(user1);
    //     vault.claim(proof, 1 ether);
        
    //     vm.prank(user1);
    //     vm.expectRevert();
    //     vault.claim(proof, 1 ether);
    // }

    // function testWithdraw() public {
    //     vm.prank(owner1);
    //     vault.deposit{value: 1 ether}();
        
    //     uint256 initialBalance = owner1.balance;
        
    //     vm.prank(owner1);
    //     vault.withdraw(0.5 ether);
        
    //     assertEq(vault.balances(owner1), 0.5 ether);
    //     assertEq(vault.totalVaultValue(), 10.5 ether);
    //     assertEq(owner1.balance, initialBalance + 0.5 ether);
    // }
}