//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SubscriptionsCollection.sol";

/**
 * @title SubscriptionsFactory
 * @author Andrea palermo - KNW Technologies
 * @notice Contract that lets merchant deploy subscriptions collections
 */
contract SubscriptionsFactory {

    /**
     * Emitted when a new subscriptions collection is deployed
     * @param collectionAddress: address of deployed contract 
     * @param paymentAmounts: prices of subscription tiers
     * @param tiersSupply: total supply of each subscription tier
     * @param paymentFrequency: subscription payment frequency
     * @param merchant: subscription issuer; it will receive the subscription payments
     * @param baseUri: base URI for tiers metadata
     * @param startTimestamp: timestamp at which subscriptions minting will be enabled
     */
    event NewCollectionCreated(string collectionName, address indexed collectionAddress, uint256[] paymentAmounts, int256[] tiersSupply, uint256 paymentFrequency, address indexed merchant, string baseUri, uint256 startTimestamp);

    /**
     * Emitted when a collection is deleted
     * @param collectionAddress: collection to delete 
     */
    event CollectionDeleted(address indexed collectionAddress);

    //all deployed subscription collections, grouped by merchant
    mapping(address => address[]) public collections;

    //all merchants that deployed at least one subscriptions collection
    address[] public merchants;

    constructor() {}

    /**
     * Creates a new subscriptions collection
     * @param paymentAmounts: prices of subscription tiers
     * @param tiersTotalSupply: total supply of each subscription tier
     * @param paymentFrequency: subscription payment frequency
     * @param merchant: subscription issuer; it will receive the subscription payments
     * @param baseUri: base URI for tiers metadata
     * @param startTimestamp: timestamp at which subscriptions minting will be enabled
     * @return collectionAddress: address of the deployed contract
     */
    function createCollection(string memory collectionName, uint256[] memory paymentAmounts, int256[] memory tiersTotalSupply, uint256 paymentFrequency, address merchant, string memory baseUri, uint256 startTimestamp) external returns (address) {
        SubscriptionsCollection newCollection = new SubscriptionsCollection(collectionName, paymentAmounts, tiersTotalSupply, paymentFrequency, merchant, baseUri, startTimestamp, address(this));
        
        address collectionAddress = address(newCollection);
        collections[merchant].push(collectionAddress);
        merchants.push(merchant);

        emit NewCollectionCreated(collectionName, collectionAddress, paymentAmounts, tiersTotalSupply, paymentFrequency, merchant, baseUri, startTimestamp);

        return collectionAddress;
    }

    /**
     * Deletes a collection of the sender, destroying the contract
     * @param collectionAddress: collection to delete 
     */
    function deleteCollection(address collectionAddress) external {
        for (uint i = 0; i < collections[msg.sender].length; i++) {
            if(collections[msg.sender][i] == collectionAddress) {
                collections[msg.sender][i] = collections[msg.sender][collections[msg.sender].length - 1];
                collections[msg.sender].pop();
                SubscriptionsCollection(collectionAddress).destroy();
                if(collections[msg.sender].length == 0) {
                    for (uint j = 0; j < merchants.length; j++) {
                        if(merchants[j] == msg.sender) {
                            merchants[j] = merchants[merchants.length - 1];
                            merchants.pop();
                        }
                    }
                }
            }
        }
    }
}