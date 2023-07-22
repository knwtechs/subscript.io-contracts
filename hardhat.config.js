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
    },
    gnosis_chiado: {
      url: "https://rpc.chiadochain.net",
      gasPrice: 100000000,
      accounts: [process.env.CHIADO_PRIVATE_KEY],
    },
    celo_alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      chainId: 44787,
      accounts: [process.env.ALFAJORES_PRIVATE_KEY],
      //gas: 4000000,
    },
    zkEVM_testnet: {
      url: `https://rpc.public.zkevm-test.net`,
      accounts: [process.env.ZKEVM_PRIVATE_KEY],
    },
    
    
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
  },

  //etherscan: {
  //  apiKey: process.env.ETHERSCAN_API_KEY,
  //}

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    customChains: [
      {
        network: "celo_alfajores",
        chainId: 44787,
        urls: {
          apiURL: "https://explorer.celo.org/alfajores/api",
          browserURL: "https://explorer.celo.org/"
        }
      }
    ]
  }

  /**settings: { optimizer: { enabled: true, runs: 200 } }*/
};
