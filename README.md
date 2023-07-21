# NFTSubscriptions

NFTSubscriptions is a decentralized application (DApp) built on the 
Ethereum blockchain that enables users to create and manage 
subscription-based services using non-fungible tokens (NFTs). This GitHub 
repository contains the source code and documentation for the 
NFTSubscriptions project.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction

NFTSubscriptions aims to provide a decentralized solution for 
subscription-based services by leveraging the capabilities of NFTs. With 
this DApp, service providers can create NFT-based subscription plans, 
allowing users to purchase these plans and enjoy the associated services. 
The project utilizes smart contracts deployed on EVM-compatible 
blockchains to ensure transparency, security, and immutability.

## Features

- **Subscription Creation**: Service providers can create subscription 
plans by defining the duration, cost, and other relevant details. Each 
subscription plan is represented by a unique NFT.
- **Subscription Purchasing**: Users can browse and purchase subscription 
plans. The ownership of the NFT represents the ownership of the 
subscription.
- **Subscription Management**: Users can view and manage their active 
subscriptions, including the ability to cancel or renew them.
- **Integration with ERC-1155**: The NFTs used in NFTSubscriptions conform 
to the ERC-1155 standard, ensuring compatibility with various wallets.

## Installation

To set up the NFTSubscriptions DApp locally, follow these steps:

1. Clone this repository:

   ```bash
   git clone https://github.com/knwtechs/NFTSubscriptions.git
   ```

2. Navigate to the project directory:

   ```bash
   cd NFTSubscriptions
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

Once the smart contracts are deployed to some network, you can 
proceed to integrate it into your own application to provide 
subscription-based services.
The usage of NFTSubscriptions involves two primary user roles:

- **Service Providers**: These are the entities that create subscription 
plans and manage their offerings.
- **Subscribers**: These are the users who browse and purchase 
subscription plans.

Both roles interact with the contracts through some dedicated functions, 
allowing for seamless subscription management and payments.


## License

NFTSubscriptions is released under the [MIT License](LICENSE). You are 
free to use, modify, and distribute this software. Refer to the 
[LICENSE](LICENSE) file for more information.
