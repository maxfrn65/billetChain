// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/BilletChain.sol";
import "../src/MockPriceFeed.sol";

contract BilletChainTest is Test {
    BilletChain public ticket;
    MockPriceFeed public mockFeed;

    address public organizer = makeAddr("organizer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant MAX_TICKETS = 5;
    uint256 public constant TICKET_PRICE_EUR = 50; // 50 Euros

    // Config de base pour l'oracle : 1 ETH = 3000 EUR
    // Avec 8 décimales, 3000 EUR = 300_000_000_000
    int256 public initialEthPrice = 3000e8;
    uint8 public oracleDecimals = 8;

    function setUp() public {
        vm.startPrank(organizer);
        // Déploiement du mock d'oracle avec prix initial, décimales et timestamp actuel
        mockFeed = new MockPriceFeed(initialEthPrice, oracleDecimals, block.timestamp);
        // Déploiement de BilletChain
        ticket = new BilletChain(address(mockFeed), MAX_TICKETS, TICKET_PRICE_EUR);
        vm.stopPrank();
    }

    // --- Tests d'initialisation ---
    function testInitialState() public view {
        assertEq(ticket.organizer(), organizer);
        assertEq(address(ticket.priceFeed()), address(mockFeed));
        assertEq(ticket.maxTickets(), MAX_TICKETS);
        assertEq(ticket.ticketPriceinEur(), TICKET_PRICE_EUR);
        assertEq(ticket.nextTokenId(), 0);
        assertFalse(ticket.paused());
    }

    // --- Tests de conversion EUR -> ETH ---
    function testConversionEurToEth() public view {
        // Taux : 1 ETH = 3000 EUR
        // Un billet à 50 EUR doit coûter : (50 * 1e18) / 3000 = 1.666...e16 Wei
        uint256 expectedEth = (50 * 1e18 * (10**oracleDecimals)) / uint256(initialEthPrice);
        uint256 actualEth = ticket.eurToEth(50);
        assertEq(actualEth, expectedEth);
    }

    // --- Tests de Vente Initiale (buyTicket) ---
    function testBuyTicketNominal() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether); // prank + balance initial

        vm.expectEmit(true, true, true, true);
        emit BilletChain.TicketBought(alice, 0, TICKET_PRICE_EUR, priceEth);

        ticket.buyTicket{value: priceEth}();

        assertEq(ticket.ownerOf(0), alice);
        assertEq(ticket.initialPriceInEur(0), TICKET_PRICE_EUR);
        assertEq(ticket.nextTokenId(), 1);
        assertEq(ticket.pendingWithdrawals(organizer), priceEth);
    }

    function testBuyTicketRefundsOverpayment() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        uint256 payment = priceEth + 1 ether;
        
        uint256 balBefore = alice.balance;
        hoax(alice, 10 ether);

        ticket.buyTicket{value: payment}();

        // Alice doit avoir été débitée du prix exact (son solde a diminué de priceEth)
        assertEq(alice.balance, 10 ether - priceEth);
        assertEq(ticket.pendingWithdrawals(organizer), priceEth);
    }

    function testBuyTicketFailsOnInsufficientPayment() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether);

        vm.expectRevert(abi.encodeWithSelector(BilletChain.PaymentIncorrect.selector, priceEth, priceEth - 1));
        ticket.buyTicket{value: priceEth - 1}();
    }

    function testBuyTicketFailsWhenFull() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);

        // On achète tous les billets autorisés
        for (uint256 i = 0; i < MAX_TICKETS; i++) {
            hoax(makeAddr(string(abi.encodePacked("buyer_", i))), 10 ether);
            ticket.buyTicket{value: priceEth}();
        }

        // Le 6ème achat doit échouer
        hoax(alice, 10 ether);
        vm.expectRevert(BilletChain.EventFull.selector);
        ticket.buyTicket{value: priceEth}();
    }

    function testBuyTicketFailsOnStalePrice() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);

        // On avance le temps au-delà de MAX_DELAY (3600s)
        vm.warp(block.timestamp + 3601);

        hoax(alice, 10 ether);
        vm.expectRevert(BilletChain.StalePrice.selector);
        ticket.buyTicket{value: priceEth}();
    }

    function testBuyTicketFailsOnInvalidPrice() public {
        // On définit le prix de l'oracle à 0 (invalide)
        mockFeed.setAnswer(0, block.timestamp);

        hoax(alice, 10 ether);
        vm.expectRevert(BilletChain.InvalidPrice.selector);
        ticket.buyTicket{value: 1 ether}();
    }

    // --- Tests de Revente (list & buyResold) ---
    function testListTicketForSaleNominal() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether);
        ticket.buyTicket{value: priceEth}();

        // Mise en vente à 55 EUR (110% de 50 EUR)
        uint256 resalePriceEur = 55;
        vm.prank(alice);
        ticket.listTicketForSale(0, resalePriceEur);

        assertTrue(ticket.ticketsForSale(0));
        assertEq(ticket.ticketSalePricesInEur(0), resalePriceEur);
    }

    function testListTicketFailsWhenNotOwner() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether);
        ticket.buyTicket{value: priceEth}();

        // Bob essaie de mettre en vente le ticket d'Alice
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(BilletChain.NotOwner.selector, alice, bob));
        ticket.listTicketForSale(0, 50);
    }

    function testListTicketFailsOnPriceTooHigh() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether);
        ticket.buyTicket{value: priceEth}();

        // 110% de 50 = 55 EUR max. Bob essaie 56 EUR.
        uint256 proposedResale = 56;
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(BilletChain.PriceTooHigh.selector, 55, proposedResale));
        ticket.listTicketForSale(0, proposedResale);
    }

    function testCancelListing() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether);
        ticket.buyTicket{value: priceEth}();

        vm.startPrank(alice);
        ticket.listTicketForSale(0, 50);
        ticket.cancelListing(0);
        vm.stopPrank();

        assertFalse(ticket.ticketsForSale(0));
        assertEq(ticket.ticketSalePricesInEur(0), 0);
    }

    function testBuyResoldTicketNominal() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether);
        ticket.buyTicket{value: priceEth}();

        // Alice met en vente à 52 EUR
        uint256 resalePriceEur = 52;
        vm.prank(alice);
        ticket.listTicketForSale(0, resalePriceEur);

        // Bob achète
        uint256 resalePriceEth = ticket.eurToEth(resalePriceEur);
        hoax(bob, 10 ether);
        ticket.buyResoldTicket{value: resalePriceEth}(0);

        assertEq(ticket.ownerOf(0), bob);
        assertFalse(ticket.ticketsForSale(0));
        assertEq(ticket.pendingWithdrawals(alice), resalePriceEth);
    }

    function testBuyResoldTicketFailsIfNotListed() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether);
        ticket.buyTicket{value: priceEth}();

        hoax(bob, 10 ether);
        vm.expectRevert(abi.encodeWithSelector(BilletChain.TicketNotForSale.selector, 0));
        ticket.buyResoldTicket{value: 1 ether}(0);
    }

    // --- Tests de Retrait (withdraw) ---
    function testWithdrawNominal() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether);
        ticket.buyTicket{value: priceEth}();

        uint256 organizerBalBefore = organizer.balance;

        vm.prank(organizer);
        ticket.withdraw();

        assertEq(organizer.balance, organizerBalBefore + priceEth);
        assertEq(ticket.pendingWithdrawals(organizer), 0);
    }

    function testWithdrawFailsOnNoFunds() public {
        vm.prank(bob);
        vm.expectRevert(BilletChain.NoFundsToWithdraw.selector);
        ticket.withdraw();
    }

    // --- Tests du Pause d'Urgence ---
    function testPauseTogglesCorrectly() public {
        vm.startPrank(organizer);
        ticket.togglePause();
        assertTrue(ticket.paused());

        ticket.togglePause();
        assertFalse(ticket.paused());
        vm.stopPrank();
    }

    function testPauseRestrictsOperations() public {
        vm.prank(organizer);
        ticket.togglePause();

        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);
        hoax(alice, 10 ether);
        vm.expectRevert(BilletChain.ContractIsPaused.selector);
        ticket.buyTicket{value: priceEth}();
    }

    // --- Tests de Consultation (getTicketsOnSaleCount) ---
    function testGetTicketsOnSaleCount() public {
        uint256 priceEth = ticket.eurToEth(TICKET_PRICE_EUR);

        // Alice achète 3 billets (tokens 0, 1, 2)
        vm.startPrank(alice);
        for (uint256 i = 0; i < 3; i++) {
            hoax(alice, 10 ether);
            ticket.buyTicket{value: priceEth}();
        }

        // Met en vente les tokens 0 et 2
        ticket.listTicketForSale(0, 50);
        ticket.listTicketForSale(2, 50);
        vm.stopPrank();

        // On interroge pour [0, 1, 2]
        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256 count = ticket.getTicketsOnSaleCount(ids);
        assertEq(count, 2);
    }
}
