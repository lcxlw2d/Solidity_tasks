const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');
const { time } = require('@nomicfoundation/hardhat-network-helpers');

describe('NftAuction Contract', function () {
  let NftAuction;
  let auction;
  let TestERC20;
  let testERC20;
  let TestERC721;
  let testERC721;
  let PriceFeedMock;
  let priceFeed;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  before(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // 部署 TestERC20 代币
    TestERC20 = await ethers.getContractFactory('TestERC20');
    testERC20 = await TestERC20.deploy(
      'Test Token',
      'TTK',
      owner.address,
      ethers.parseEther('1000000')
    );

    // 部署 TestERC721 NFT
    TestERC721 = await ethers.getContractFactory('TestERC721');
    testERC721 = await TestERC721.deploy();

    // 部署 Mock Price Feed
    PriceFeedMock = await ethers.getContractFactory('PriceFeedMock');
    priceFeed = await PriceFeedMock.deploy();
    await priceFeed.setPrice(200000000); // 设置价格为 $200 (8 decimals)

    // 部署可升级的 NftAuction 合约
    NftAuction = await ethers.getContractFactory('NftAuction');
    auction = await upgrades.deployProxy(NftAuction, [], {
      initializer: 'initialize',
    });
    await auction.waitForDeployment();

    // 设置价格喂价
    await auction
      .connect(owner)
      .setPriceFeed(ethers.ZeroAddress, priceFeed.target);
    await auction
      .connect(owner)
      .setPriceFeed(testERC20.target, priceFeed.target);

    // 给测试用户分配 ERC20 代币
    await testERC20
      .connect(owner)
      .transfer(addr1.address, ethers.parseEther('1000'));
    await testERC20
      .connect(owner)
      .transfer(addr2.address, ethers.parseEther('1000'));

    // 铸造 NFT 并授权给拍卖合约
    await testERC721.connect(owner).mint(owner.address, 1);
    await testERC721.connect(owner).approve(auction.target, 1);
  });

  describe('Initialization', function () {
    it('Should set the right admin', async function () {
      expect(await auction.admin()).to.equal(owner.address);
    });

    it('Should initialize with auctionId 0', async function () {
      expect(await auction.auctionId()).to.equal(0);
    });

    it('Should be upgradeable', async function () {
      const NftAuctionV2 = await ethers.getContractFactory('NftAuction');
      const auctionV2 = await upgrades.upgradeProxy(
        auction.target,
        NftAuctionV2
      );
      expect(auctionV2.target).to.equal(auction.target);
    });
  });

  describe('Price Feed', function () {
    it('Should allow admin to set price feed', async function () {
      await auction
        .connect(owner)
        .setPriceFeed(addr1.address, priceFeed.target);
      expect(await auction.priceFeeds(addr1.address)).to.equal(
        priceFeed.target
      );
    });

    it('Should prevent non-admin from setting price feed', async function () {
      await expect(
        auction.connect(addr1).setPriceFeed(addr1.address, priceFeed.target)
      ).to.be.revertedWith('Only admin can set price feed');
    });

    it('Should get latest price correctly', async function () {
      const price = await auction.getLatestPrice(ethers.ZeroAddress);
      expect(price).to.equal(200000000); // $200
    });
  });

  describe('Auction Creation', function () {
    it('Should create a new ETH auction', async function () {
      await auction.connect(owner).createAuction(
        testERC721.target,
        1,
        ethers.parseEther('1'), // 1 ETH start price
        (await time.latest()) + 60, // start in 60 seconds
        3600, // 1 hour duration
        ethers.ZeroAddress // ETH auction
      );

      const auctionInfo = await auction.auctions(0);
      expect(auctionInfo.tokenId).to.equal(1);
      expect(auctionInfo.nftContract).to.equal(testERC721.target);
      expect(auctionInfo.startPrice).to.equal(ethers.parseEther('1'));
      expect(auctionInfo.duration).to.equal(3600);
      expect(await auction.auctionId()).to.equal(1);
    });

    it('Should create a new ERC20 auction', async function () {
      await auction.connect(owner).createAuction(
        testERC721.target,
        1,
        ethers.parseEther('100'), // 100 tokens start price
        (await time.latest()) + 60,
        3600,
        testERC20.target // ERC20 auction
      );

      const auctionInfo = await auction.auctions(1);
      expect(auctionInfo.tokenAddress).to.equal(testERC20.target);
    });

    it('Should prevent non-admin from creating auction', async function () {
      await expect(
        auction
          .connect(addr1)
          .createAuction(
            testERC721.target,
            1,
            ethers.parseEther('1'),
            (await time.latest()) + 60,
            3600,
            ethers.ZeroAddress
          )
      ).to.be.revertedWith('You are not the owner of this NFT');
    });

    it('Should require valid duration', async function () {
      await expect(
        auction.connect(owner).createAuction(
          testERC721.target,
          1,
          ethers.parseEther('1'),
          (await time.latest()) + 60,
          5, // Too short duration
          ethers.ZeroAddress
        )
      ).to.be.revertedWith('Duration must be greater than 10');
    });

    it('Should require positive start price', async function () {
      await expect(
        auction.connect(owner).createAuction(
          testERC721.target,
          1,
          0, // Zero price
          (await time.latest()) + 60,
          3600,
          ethers.ZeroAddress
        )
      ).to.be.revertedWith('Start price must be greater than 0');
    });
  });

  describe('Bidding', function () {
    beforeEach(async function () {
      // 创建一个新的ETH拍卖
      await auction.connect(owner).createAuction(
        testERC721.target,
        1,
        ethers.parseEther('1'), // 1 ETH start price
        await time.latest(), // start now
        3600, // 1 hour duration
        ethers.ZeroAddress // ETH auction
      );
    });

    it('Should accept ETH bid higher than start price', async function () {
      const bidAmount = ethers.parseEther('1.5');
      await expect(
        auction
          .connect(addr1)
          .bid(0, bidAmount, ethers.ZeroAddress, { value: bidAmount })
      ).to.changeEtherBalances([addr1, auction], [bidAmount * -1n, bidAmount]);

      const auctionInfo = await auction.auctions(0);
      expect(auctionInfo.highestBid).to.equal(bidAmount);
      expect(auctionInfo.highestBidder).to.equal(addr1.address);
    });

    it('Should accept ERC20 bid with sufficient allowance', async function () {
      // 创建一个ERC20拍卖
      await auction.connect(owner).createAuction(
        testERC721.target,
        1,
        ethers.parseEther('100'), // 100 tokens start price
        await time.latest(),
        3600,
        testERC20.target
      );

      const bidAmount = ethers.parseEther('150');
      await testERC20.connect(addr1).approve(auction.target, bidAmount);

      await expect(
        auction.connect(addr1).bid(1, bidAmount, testERC20.target)
      ).to.changeTokenBalances(
        testERC20,
        [addr1, auction],
        [bidAmount * -1n, bidAmount]
      );
    });

    it('Should reject bid lower than current highest', async function () {
      const firstBid = ethers.parseEther('1.5');
      await auction
        .connect(addr1)
        .bid(0, firstBid, ethers.ZeroAddress, { value: firstBid });

      const secondBid = ethers.parseEther('1.2');
      await expect(
        auction
          .connect(addr2)
          .bid(0, secondBid, ethers.ZeroAddress, { value: secondBid })
      ).to.be.revertedWith('Bid price is too low');
    });

    it('Should refund previous highest bidder', async function () {
      const firstBid = ethers.parseEther('1.5');
      await auction
        .connect(addr1)
        .bid(0, firstBid, ethers.ZeroAddress, { value: firstBid });

      const secondBid = ethers.parseEther('2');
      await expect(
        auction
          .connect(addr2)
          .bid(0, secondBid, ethers.ZeroAddress, { value: secondBid })
      ).to.changeEtherBalances(
        [addr1, addr2, auction],
        [firstBid, secondBid * -1n, secondBid - firstBid]
      );
    });

    it('Should reject bid after auction end time', async function () {
      await time.increase(3601); // 快进到拍卖结束

      await expect(
        auction
          .connect(addr1)
          .bid(0, ethers.parseEther('1.5'), ethers.ZeroAddress, {
            value: ethers.parseEther('1.5'),
          })
      ).to.be.revertedWith('Auction has ended');
    });
  });

  describe('Ending Auction', function () {
    beforeEach(async function () {
      // 创建一个拍卖并接受出价
      await auction
        .connect(owner)
        .createAuction(
          testERC721.target,
          1,
          ethers.parseEther('1'),
          await time.latest(),
          3600,
          ethers.ZeroAddress
        );
      await auction
        .connect(addr1)
        .bid(0, ethers.parseEther('1.5'), ethers.ZeroAddress, {
          value: ethers.parseEther('1.5'),
        });
    });

    it('Should end auction correctly', async function () {
      await time.increase(3601); // 快进到拍卖结束

      await expect(auction.connect(owner).endAuction(0)).to.changeEtherBalances(
        [auction, owner],
        [ethers.parseEther('-1.5'), ethers.parseEther('1.5')]
      );

      const auctionInfo = await auction.auctions(0);
      expect(auctionInfo.ended).to.be.true;
      expect(await testERC721.ownerOf(1)).to.equal(addr1.address);
    });

    it('Should prevent ending before auction time', async function () {
      await expect(auction.connect(owner).endAuction(0)).to.be.revertedWith(
        'Auction has ended'
      );
    });

    it('Should prevent non-admin from ending auction', async function () {
      await time.increase(3601);
      await expect(auction.connect(addr1).endAuction(0)).to.be.reverted; // 虽然没有明确错误信息，但只有admin能结束
    });
  });

  describe('UUPS Upgrade', function () {
    it('Should allow admin to upgrade', async function () {
      const NftAuctionV2 = await ethers.getContractFactory('NftAuction');
      await upgrades.upgradeProxy(auction.target, NftAuctionV2);
    });

    it('Should prevent non-admin from upgrading', async function () {
      const NftAuctionV2 = await ethers.getContractFactory('NftAuction');
      await expect(
        upgrades.upgradeProxy(auction.target, NftAuctionV2.connect(addr1))
      ).to.be.revertedWith('Only admin can upgrade');
    });
  });
});
