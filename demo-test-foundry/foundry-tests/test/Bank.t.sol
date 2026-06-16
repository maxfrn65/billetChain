pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/Bank.sol";

contract BankTest is Test {

    Bank bank; 

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.prank(owner); // le owner du contrat    
        bank = new Bank();

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testDeposit() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        assertEq(bank.balanceOf(alice), 1 ether);
    }
}