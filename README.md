# SubScript.io

SubScript.io is a decentralized application (DApp) built on the 
Ethereum blockchain that enables users to create and manage 
subscription-based services using ERC1155 non-fungible tokens (NFTs). This 
repository contains the source code, documentation, deployment, and testing scripts
for the SubScript.io smart contracts.

## Table of Contents

- [Introduction](#introduction)
- [Blockchains](#blockchains)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Introduction

SubScript.io endeavors to offer a decentralized solution for subscription-based services by leveraging the capabilities of Non-Fungible Tokens (NFTs). Utilizing this Decentralized Application, service providers gain the ability to create NFT-based subscription plans, which may encompass various tiers. Consequently, users are empowered to acquire these plans and thereby access the respective services.

Upon payment of the recurring subscription fees, subscribers shall possess the NFTs, enabling them to retain ownership as long as they continue meeting the recurrent payment obligations. Additionally, subscribers shall be afforded the facility to transfer the ownership of the subscription tokens to other users. This allows users who have bought a subscription and find themselves no longer in need of the associated services to potentially recoup some expenses by selling the subscription token prematurely.

To ensure the integrity and reliability of the system, the project relies on smart contracts deployed on blockchains compatible with the Ethereum Virtual Machine (EVM). The utilization of such technology further guarantees transparency, security, and immutability in the execution of the subscription-based services facilitated by SubScript.io.

## Blockchains

The smart contracts have been deployed to various blockchains. This is the up-to-date list of all supported chains, together with the links to the contract page on block explorers (all the contracts are verified):

- Ethereum Sepolia testnet: [block explorer contract url](https://sepolia.etherscan.io/address/0x0abec91137108c54bdfa2b909e0ec529ecd99429)
- Linea goerli testnet: [block explorer contract url](https://goerli.lineascan.build/address/0x4b17e43e1ab6b6d2f6fb4978bb2ea0b9285b9603)
- Polygon zkEVM: [block explorer contract url](https://testnet-zkevm.polygonscan.com/address/0x29970f81d73d418e8a4c137c7de917aa51c50838)
- Neon EVM devnet: [block explorer contract url](https://devnet.neonscan.org/address/0x4b17E43E1Ab6b6D2F6FB4978BB2ea0b9285b9603)
- Gnosis chiado testnet: [block explorer contract url](https://gnosis-chiado.blockscout.com/address/0x29970f81D73D418E8A4C137c7DE917aa51C50838)
- Celo Alfajores testnet: [block explorer contract url](https://alfajores.celoscan.io/address/0x29970f81d73d418e8a4c137c7de917aa51c50838)
- Mantle testnet: [block explorer contract url](https://explorer.testnet.mantle.xyz/address/0xe3BBC3055DB96ecCDb1143B2DbfB8154fC4B211E)

## Features

- **Subscription Creation**: Service providers can create subscription 
plans by defining the duration, cost, and other relevant details. Each 
subscription plan is represented by a unique NFT.
- **Subscription Purchasing**: Users can browse and purchase subscription 
plans. The ownership of the NFT represents the ownership of the 
subscription.
- **Subscription Transferring**: Subscribers can transfer their subscriptions to other users.
- **Subscription Management**: Users can view and manage their active 
subscriptions, including the ability to cancel or renew them.
- **Integration with ERC-1155**: The NFTs used in SubScript.io conform 
to the ERC-1155 standard, ensuring compatibility with various wallets and NFT ecosystems.
- **ETH Payments**: All the subscription prices are paid in the native blockchain cryptocurrencies, avoiding the hassle of having to buy non-native tokens.

## Installation

To set up the SubScript.io DApp locally, follow these steps:

1. Clone this repository:

   ```bash
   git clone https://github.com/knwtechs/subscript.io-contracts.git
   ```

2. Navigate to the project directory:

   ```bash
   cd subscript.io-contracts
   ```

3. Install the required dependencies:

   ```bash
   npm install
   ```

4. Compile the smart contracts:

   ```bash
   npx hardhat compile
   ```

4.1 [Optional] Test the smart contracts:

   ```bash
   npx hardhat test
   ```

5. Deploy the smart contracts to any network (networks must be defined in 
hardhat.config.js):

   ```bash
   npx hardhat run scripts/deploy.js --network <network-name>
   ```

   Replace `<network-name>` with the target network.

## Usage

Being the contracts deployed on various networks, you can 
proceed to integrate it into your own application to provide 
subscription-based services. An example Near BOS decentralized front-end has been
developed by our company and is available at the following [repository](https://github.com/knwtechs/subscript.io-bos.git)


## License

SubScript.io is released under the [MIT License](LICENSE). You are 
free to use, modify, and distribute this software. Refer to the 
[LICENSE](LICENSE) file for more information.
