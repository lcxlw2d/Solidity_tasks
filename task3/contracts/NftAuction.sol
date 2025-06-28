// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NftAuction is Initializable, UUPSUpgradeable {
    // 定义一个拍卖结构体
    struct Auction {
        // 拍卖的NFT的ID
        uint256 tokenId;
        // 拍卖的NFT的合约地址
        address nftContract;
        // 拍卖的NFT的拥有者
        address seller;
        uint256 startPrice;
        // 拍卖的NFT的当前价格
        uint256 highestBid;
        // 最高出价者
        address highestBidder;
        // 拍卖的NFT的开始时间
        uint256 startTime;
        // 拍卖的NFT的持续时间
        uint256 duration;
        // 是否结束
        bool ended;
        // 竞价的资产类型, 0x地址代表ETH，其他代表ERC20代币
        address tokenAddress;
    }
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionId;
    address public admin;

    // 喂价映射
    mapping(address => AggregatorV3Interface) public priceFeeds;

    function initialize() public initializer {
        admin = msg.sender;
    }

    function setPriceFeed(address tokenAddress, address priceFeed) public {
        require(msg.sender == admin, "Only admin can set price feed");
        priceFeeds[tokenAddress] = AggregatorV3Interface(priceFeed);
    }

    function getLatestPrice(
        address tokenAddress
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // 创建拍卖
    function createAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startTime,
        uint256 duration,
        address tokenAddress
    ) external {
        // 创建拍卖的NFT的拥有者
        address seller = msg.sender;

        require(admin == seller, "You are not the owner of this NFT");
        require(duration > 10, "Duration must be greater than 10");
        require(startPrice > 0, "Start price must be greater than 0");
        IERC721(nftAddress).approve(address(this), tokenId);
        // 创建拍卖的NFT的合约地址
        auctions[auctionId] = Auction({
            tokenId: tokenId,
            nftContract: nftAddress,
            seller: seller,
            startPrice: startPrice,
            duration: duration,
            ended: false,
            highestBid: 0,
            highestBidder: address(0),
            startTime: block.timestamp,
            tokenAddress: tokenAddress
        });
        // 创建拍卖的NFT的ID
        auctionId++;
    }

    // 竞价
    function bid(
        uint256 auctionId,
        uint256 amount,
        address tokenAddress
    ) public payable {
        Auction storage auction = auctions[auctionId];
        require(
            !auction.ended &&
                auction.startTime + auction.duration > block.timestamp,
            "Auction has ended"
        );
        uint256 bidPriceValue;
        if (auction.tokenAddress == address(0)) {
            amount = msg.value;
            bidPriceValue = amount * uint(getLatestPrice(address(0)));
        } else {
            // ERC20代币价值
            bidPriceValue = amount * uint(getLatestPrice(tokenAddress));
        }
        uint startPriceValue = auction.startPrice *
            uint(getLatestPrice(tokenAddress));
        uint highestBidValue = auction.highestBid *
            uint(getLatestPrice(tokenAddress));
        require(
            bidPriceValue >= startPriceValue && bidPriceValue > highestBidValue,
            "Bid price is too low"
        );
        // 最高价更新，接收出价，并退还之前最高价者的代币
        // 转移ERC20到合约
        if (tokenAddress != address(0)) {
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
        if (auction.highestBidder != address(0)) {
            // 退还ERC20
            IERC20(tokenAddress).transfer(
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            // 退还ETH
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Transfer failed"
        );
        // 更新竞价信息
        auction.highestBid = amount;
        auction.highestBidder = msg.sender;
        auction.tokenAddress = tokenAddress;
    }

    // 结束竞价
    function endAuction() public {
        Auction storage auction = auctions[auctionId];
        require(
            !auction.ended &&
                auction.startTime + auction.duration > block.timestamp,
            "Auction has ended"
        );
        // 转移NFT到最高出价者
        IERC721(auction.nftContract).transferFrom(
            admin,
            auction.highestBidder,
            auction.tokenId
        );
        // 转移剩余资金到卖家
        payable(auction.seller).transfer(address(this).balance);
        auction.ended = true;
    }

    receive() external payable {}

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        require(msg.sender == admin, "Only admin can upgrade");
    }
}
