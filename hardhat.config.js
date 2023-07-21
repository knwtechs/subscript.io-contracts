require('dotenv').config('.env');
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    linea: {
      url: `https://linea-goerli.infura.io/v3/${process.env.LINEA_API_KEY}`,
      accounts: [process.env.LINEA_PRIVATE_KEY],
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.SEPOLIA_API_KEY}`,
      accounts: [process.env.SEPOLIA_PRIVATE_KEY]
    },
    neonlabs_devnet: {
      url: "https://devnet.neonevm.org",
      accounts: [process.env.NEON_DEVNET_PRIVATE_KEY],
      network_id: 245022926,
      //chainId: 245022926,
      allowUnlimitedContractSize: false,
      timeout: 1000000,
      isFork: true
    }
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  gasReporter: {
    enabled: true
  }

  /**settings: { optimizer: { enabled: true, runs: 200 } }*/
};
