// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/Exercice_1.sol";

contract CounterTest is Test {
    Counter counter;

    address owner = makeAddr("owner");
    address alice = makeAddr("Alice");

    function setUp() public {
        vm.prank(owner);
        counter = new Counter();
    }

    function testOwnerEstLeDeployeur() public view {
        assertEq(counter.owner(), owner);
    }

    function testCounterInitialZero() public  view {
        assertEq(counter.count(), 0);
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.count(), 1);
        counter.increment();
        assertEq(counter.count(), 2);
    }

    function testIncrementBy() public {
        
        counter.incrementBy(42);
        assertEq(counter.count(), 42);
    }

    function testIncrementByMaxAutorise() public {
        counter.incrementBy(100); 
        assertEq(counter.count(), 100);
    }

    function testIncrementByTropGrandRevert() public {
        vm.expectRevert(abi.encodeWithSelector(Counter.TooLarge.selector, 101));
        counter.incrementBy(101);
    }
}