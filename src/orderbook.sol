// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract OrderBook is ReentrancyGuard {
    struct Order {
        address user;
        uint256 volume;
        uint256 price;
    }

    Order[] public buyOrders;
    Order[] public sellOrders;
    Order[] public orderHistory;

    IERC20 public tokenA;
    IERC20 public tokenB;

    event NewBuyOrder(address indexed buyer, uint256 volume, uint256 price);
    event NewSellOrder(address indexed seller, uint256 volume, uint256 price);
    event OrderMatched(
        address indexed buyer,
        address indexed seller,
        uint256 volume,
        uint256 price
    );

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function buy(uint256 _volume, uint256 _price) public payable {
        require(msg.value == _price, "Incorrect ETH amount sent");

        for (uint i = 0; i < sellOrders.length; i++) {
            if (sellOrders[i].volume == _volume && sellOrders[i].price == _price) {
                require(tokenA.transfer(msg.sender, _volume), "Transfer of tokenA failed");
                (bool success, ) = sellOrders[i].user.call{value: _price}("");
                require(success, "Transfer of ETH failed");

                emit OrderMatched(msg.sender, sellOrders[i].user, _volume, _price);
                orderHistory.push(sellOrders[i]);
                removeSellOrder(i);
                return;
            }
        }
        buyOrders.push(Order(msg.sender, _volume, _price));
        emit NewBuyOrder(msg.sender, _volume, _price);
    }

    function sell(uint256 _volume, uint256 _price) public {
        require(tokenA.transferFrom(msg.sender, address(this), _volume), "Transfer of tokenA failed");

        for (uint i = 0; i < buyOrders.length; i++) {
            if (buyOrders[i].volume == _volume && buyOrders[i].price == _price) {
                require(tokenA.transfer(buyOrders[i].user, _volume), "Transfer of tokenA failed");
                (bool success, ) = payable(msg.sender).call{value: _price}("");
                require(success, "Transfer of ETH failed");

                emit OrderMatched(buyOrders[i].user, msg.sender, _volume, _price);
                orderHistory.push(buyOrders[i]);
                removeBuyOrder(i);
                return;
            }
        }
        sellOrders.push(Order(msg.sender, _volume, _price));
        emit NewSellOrder(msg.sender, _volume, _price);
    }

    function removeSellOrder(uint256 index) public {
        if (index != sellOrders.length - 1) {
            sellOrders[index] = sellOrders[sellOrders.length - 1];
        }
        sellOrders.pop();
    }

    function removeBuyOrder(uint256 index) public {
        if (index != buyOrders.length - 1) {
            buyOrders[index] = buyOrders[buyOrders.length - 1];
        }
        buyOrders.pop();
    }

    function getBuysLength() public view returns (uint256) {
        return buyOrders.length;
    }

    function getSellsLength() public view returns (uint256) {
        return sellOrders.length;
    }
}
