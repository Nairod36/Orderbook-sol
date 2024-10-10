// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/OrderBook.sol";
import "../src/ERC20Mock.sol"; // Importer le contrat ERC20Mock

contract OrderBookTest is Test {
    OrderBook private orderBook;
    ERC20Mock private tokenA;
    ERC20Mock private tokenB;
    address private buyer;
    address private seller;

    function setUp() public {
        buyer = address(1);
        seller = address(2);

        // Créer des tokens ERC20 pour les tests
        tokenA = new ERC20Mock("Token A", "TKA", 10000 * 10 ** 18);
        tokenB = new ERC20Mock("Token B", "TKB", 10000 * 10 ** 18);

        // Créer un carnet d'ordres avec les adresses des tokens
        orderBook = new OrderBook(address(tokenA), address(tokenB));

        // Distribuer des tokens et des ETH aux utilisateurs
        deal(address(tokenA), seller, 1000 * 10 ** 18); // 1000 Token A au vendeur
        deal(address(tokenB), buyer, 1000 * 10 ** 18);  // 1000 Token B à l'acheteur

        vm.deal(buyer, 10 ether);  // 10 ETH pour l'acheteur
        vm.deal(seller, 10 ether); // 10 ETH pour le vendeur

        // Approuver les tokens pour le carnet d'ordres
        vm.prank(seller);
        tokenA.approve(address(orderBook), 1000 * 10 ** 18);
    }

    function testBuyOrder() public {
        // Créer un ordre d'achat avec 1 ETH pour 100 Token A
        vm.prank(buyer);
        orderBook.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);

        // Vérifier que l'ordre d'achat est enregistré
        (address orderer, uint256 volume, uint256 price) = orderBook.buyOrders(0);
        assertEq(orderer, buyer);
        assertEq(volume, 100 * 10 ** 18);
        assertEq(price, 1 ether);
    }

    function testSellOrder() public {
        // Créer un ordre de vente pour 100 Token A contre 1 ETH
        vm.prank(seller);
        orderBook.sell(100 * 10 ** 18, 1 ether);

        // Vérifier que l'ordre de vente est enregistré
        (address orderer, uint256 volume, uint256 price) = orderBook.sellOrders(0);
        assertEq(orderer, seller);
        assertEq(volume, 100 * 10 ** 18);
        assertEq(price, 1 ether);
    }

    function testMatchOrder() public {
        uint256 initialBuyerBalance = buyer.balance; // Solde initial de l'acheteur
        uint256 initialSellerBalance = seller.balance; // Solde initial du vendeur

        // Créer un ordre d'achat
        vm.prank(buyer);
        orderBook.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);

        // Créer un ordre de vente correspondant
        vm.prank(seller);
        orderBook.sell(100 * 10 ** 18, 1 ether);

        // Vérifier que l'ordre d'achat et de vente ont été appariés et retirés
        assertEq(orderBook.getBuysLength(), 0);
        assertEq(orderBook.getSellsLength(), 0);

        // Vérifier les soldes après l'appariement
        uint256 finalBuyerBalance = buyer.balance;
        uint256 finalSellerBalance = seller.balance;

        // Le vendeur doit recevoir 1 ETH, l'acheteur doit dépenser 1 ETH
        assertEq(finalBuyerBalance, initialBuyerBalance - 1 ether);
        assertEq(finalSellerBalance, initialSellerBalance + 1 ether);
    }

    function testFailIncorrectETHAmount() public {
        // Tester un achat avec un montant d'ETH incorrect
        vm.prank(buyer);
        orderBook.buy{value: 0.5 ether}(100 * 10 ** 18, 1 ether); // Envoyer 0.5 ETH au lieu de 1 ETH
    }

    function testFailSellWithoutApproval() public {
        // Essayer de vendre des tokens sans approbation
        vm.prank(seller);
        tokenA.approve(address(orderBook), 0); // Pas d'approbation pour les tokens
        orderBook.sell(100 * 10 ** 18, 1 ether);
    }

    function testRemoveBuyOrder() public {
        // Créer un ordre d'achat
        vm.prank(buyer);
        orderBook.buy{value: 1 ether}(100 * 10 ** 18, 1 ether);

        // Vérifier la longueur de la liste des ordres d'achat
        assertEq(orderBook.getBuysLength(), 1);

        // Supprimer l'ordre d'achat
        orderBook.removeBuyOrder(0);

        // Vérifier que l'ordre a été supprimé
        assertEq(orderBook.getBuysLength(), 0);
    }

    function testRemoveSellOrder() public {
        // Créer un ordre de vente
        vm.prank(seller);
        orderBook.sell(100 * 10 ** 18, 1 ether);

        // Vérifier la longueur de la liste des ordres de vente
        assertEq(orderBook.getSellsLength(), 1);

        // Supprimer l'ordre de vente
        orderBook.removeSellOrder(0);

        // Vérifier que l'ordre a été supprimé
        assertEq(orderBook.getSellsLength(), 0);
    }
}
