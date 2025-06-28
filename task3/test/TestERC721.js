const { expect } = require('chai');
const { deployments, ethers, getNamedAccounts } = require('hardhat');
const { time } = require('@nomicfoundation/hardhat-network-helpers');

describe('NftAuction Contract', function () {
  let auction;
  let testERC20;
  let testERC721;
  let priceFeed;
  let deployer, admin, addr1, addr2;

  before(async function () {
    // 获取命名账户
    [deployer, admin, addr1, addr2] = await ethers.getSigners();

    // 使用hardhat-deploy的fixture系统
    await deployments.fixture(['all']);

    // 获取已部署的合约实例
    auction = await ethers.getContract('NftAuction', admin);
    testERC20 = await ethers.getContract('TestERC20', admin);
    testERC721 = await ethers.getContract('TestERC721', admin);
    priceFeed = await ethers.getContract('PriceFeedMock', admin);

    // 设置价格喂价
    await auction
      .connect(admin)
      .setPriceFeed(ethers.ZeroAddress, priceFeed.target);
    await auction
      .connect(admin)
      .setPriceFeed(testERC20.target, priceFeed.target);

    // 分配代币
    await testERC20
      .connect(admin)
      .transfer(addr1.address, ethers.parseEther('1000'));
    await testERC20
      .connect(admin)
      .transfer(addr2.address, ethers.parseEther('1000'));

    // 铸造NFT并授权
    await testERC721.connect(admin).mint(admin.address, 1);
    await testERC721.connect(admin).approve(auction.target, 1);
  });

  // ...保持之前的测试用例不变...
});
