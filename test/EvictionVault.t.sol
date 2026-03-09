// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVaultCorrections.sol";

contract EvictionVaultTest is Test {
    EvictionVaultCorrections vault;
    address owner1;
    address owner2;
    address owner3;
    address user1;

    function setUp() public {
        owner1 = address(0x1);
        owner2 = address(0x2);
        owner3 = address(0x3);
        user1 = address(0x4);

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        //vm.prank(owner1);
        vault = new EvictionVaultCorrections{value: 10 ether}(owners, 2);
    }

    
    function testDeposit() public {
        deal(user1, 5 ether);
        vm.prank(user1);
        
        vault.deposit{value: 1 ether}();
        
        assertEq(vault.balances(user1), 1 ether);
        assertEq(vault.totalVaultValue(), 1 ether);
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

    
    function testSubmitTransactionRevertNonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        vault.submitTransaction(user1, 1 ether, "");
    }
}