// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "forge-std/Test.sol";
import "../src/Exercice_2.sol";

contract WhitelistTest is Test {
    Whitelist wl;

    address admin = makeAddr("admin");
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        vm.prank(admin);
        wl = new Whitelist();
    }

    // ---------- état initial ----------

    function testAdminEstLeDeployeur() public view {
        assertEq(wl.admin(), admin);
    }

    function testCompteurInitialZero() public view {
        assertEq(wl.whitelistedCount(), 0);
    }

    // ---------- addToWhitelist ----------

    function testAddToWhitelist() public {
        vm.prank(admin);
        wl.addToWhitelist(alice);

        assertTrue(wl.isWhitelisted(alice));
        assertEq(wl.whitelistedCount(), 1);
    }

    function testAddEmetEvent() public {
        // on attend l'event Whitelisted(alice)
        vm.expectEmit(true, false, false, false);
        emit Whitelist.Whitelisted(alice);

        vm.prank(admin);
        wl.addToWhitelist(alice);
    }

    function testAddParNonAdminRevert() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Whitelist.NotAdmin.selector, alice));
        wl.addToWhitelist(bob);
    }

    function testAddDoublonRevert() public {
        vm.startPrank(admin);
        wl.addToWhitelist(alice);
        vm.expectRevert(Whitelist.AlreadyWhitelisted.selector);
        wl.addToWhitelist(alice);   // déjà whitelisté
        vm.stopPrank();
    }

    // ---------- removeFromWhitelist ----------

    function testRemoveFromWhitelist() public {
        vm.startPrank(admin);
        wl.addToWhitelist(alice);
        wl.removeFromWhitelist(alice);
        vm.stopPrank();

        assertFalse(wl.isWhitelisted(alice));
        assertEq(wl.whitelistedCount(), 0);
    }

    function testRemoveEmetEvent() public {
        vm.startPrank(admin);
        wl.addToWhitelist(alice);

        vm.expectEmit(true, false, false, false);
        emit Whitelist.Unwhitelisted(alice);
        wl.removeFromWhitelist(alice);
        vm.stopPrank();
    }

    function testRemoveNonWhitelisteRevert() public {
        vm.prank(admin);
        vm.expectRevert(Whitelist.NotWhitelisted.selector);
        wl.removeFromWhitelist(alice); // jamais ajouté
    }

    function testRemoveParNonAdminRevert() public {
        vm.prank(admin);
        wl.addToWhitelist(alice);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Whitelist.NotAdmin.selector, bob));
        wl.removeFromWhitelist(alice);
    }

    // ---------- addBatch ----------

    function testAddBatch() public {
        address[] memory users = new address[](3);
        users[0] = alice;
        users[1] = bob;
        users[2] = carol;

        vm.prank(admin);
        wl.addBatch(users);

        assertTrue(wl.isWhitelisted(alice));
        assertTrue(wl.isWhitelisted(bob));
        assertTrue(wl.isWhitelisted(carol));
        assertEq(wl.whitelistedCount(), 3);
    }

    function testAddBatchIgnoreLesDoublons() public {
        // alice est déjà whitelistée → addBatch ne doit pas la recompter
        vm.prank(admin);
        wl.addToWhitelist(alice);

        address[] memory users = new address[](2);
        users[0] = alice;  // doublon
        users[1] = bob;

        vm.prank(admin);
        wl.addBatch(users);

        // alice (déjà là) + bob (nouveau) = compteur à 2, pas 3
        assertEq(wl.whitelistedCount(), 2);
    }

    function testAddBatchParNonAdminRevert() public {
        address[] memory users = new address[](1);
        users[0] = alice;

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Whitelist.NotAdmin.selector, bob));
        wl.addBatch(users);
    }

    // ---------- getWhiteList ----------

    function testGetWhiteListVrai() public {
        vm.prank(admin);
        wl.addToWhitelist(alice);
        assertTrue(wl.getWhiteList(alice));
    }

    function testGetWhiteListNonWhitelisteRevert() public {
        vm.expectRevert(Whitelist.NotWhitelisted.selector);
        wl.getWhiteList(alice);
    }
}
