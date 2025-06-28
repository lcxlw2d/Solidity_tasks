require('@nomicfoundation/hardhat-toolbox');
require('hardhat-deploy');
require('dotenv').config();
/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: '0.8.28',
  namedAccounts: {
    deployer: 0,
    user1: 1,
    user2: 2,
  },
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545', // 默认 Hardhat 节点地址
      chainId: 31337, // Hardhat 网络的默认链 ID
      // 不需要 accounts 配置，Hardhat 会自动提供测试账户
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.PK],
    },
  },
};
