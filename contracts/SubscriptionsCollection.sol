//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

/**
 * @title SubscriptionsCollection
 * @author Andrea Palermo - KNW Technologies
 * @notice Collection contract for ERC1155 NFT subscriptions
 */
contract SubscriptionsCollection is ERC1155URIStorage { 


    struct SubscriptionInfo {
        uint256 deadline;           //Subscription deadline
        address transferApproved;   //Address approved by subscription owner for transfering subscription token
    }


    /**
     * Emitted on subscription start and deadline update.
     * @param tier: subscription tier
     * @param owner: subscription owner
     * @param deadline: new subscription deadline
     */
    event SubscriptionUpdate(uint256 indexed tier, address indexed owner, uint256 deadline);

    /**
     * Emitted on subscription termination
     * @param tier: subscription tier
     * @param owner: subscription owner
     */
    event SubscriptionTermination(uint256 indexed tier, address indexed owner);

    /**
     * Emitted when a subscription token is transfered
     * @param tier: subscription tier
     * @param from: subscription ex owner
     * @param to: subscription new owner
     */
    event SubscriptionTokenTransfer(uint256 indexed tier, address indexed from, address indexed to); 

    /**
     * Emitted when the address approved for subscription token transfer is changed or reaffirmed.
     * The zero address indicates there is no approved address (approval removal).
     * @param approver: subscription owner
     * @param approved: address approved for transfer 
     * @param tier: subscrtiption tier
     */
    event SubscriptionTokenTransferApproval(address indexed approver, address indexed approved, uint256 indexed tier);

    /**
     * Emitted when the merchant creates new subscription tiers
     * @param paymentAmounts: new tiers' prices
     * @param tiers: new tiers
     */
    event NewTiers(uint256[] paymentAmounts, uint256[] tiers);
    
    /**
     * Emitted when the merchant disables subscription tiers
     * @param tiers: disabled tiers
     */
    event TiersDisabled(uint256[] tiers);

    /**
     * Emitted when the merchant changes
     * @param oldMerchant: ex merchant 
     * @param newMerchant: new merchant
     */
    event MerchantTransfer(address oldMerchant, address newMerchant);


    //mapping that stores the subscription details of each active subscritpion
    mapping(address => mapping(uint256 => SubscriptionInfo)) private _subscriptions;

    //recurrent price of each tier
    uint256[] private _paymentAmounts;

    //frequency of recurrent paymentes
    uint256 private _paymentFrequency;

    //subscriptions seller
    address payable private _merchant;

    //timestamp after which mint is enabled
    uint256 private _startTimestamp;

    //number of different subscrition tiers
    uint256 private _nTiers;

    //mapping from tier number to total and circulating supplies of each tier
    mapping(uint256 => int256[2]) private _tiersSupplies;

    //active and inactive tiers
    mapping (uint256 => bool) private _activeTiers;

    //price set by the merchant to transfer merchant rights
    uint256 private _merchantPrice;

    //indicates wether merchant is selling the collection or not
    bool public onSale;

    //address of the factory contract from wich the collection was created
    address private _factoryAddress;

    //collection name
    string public collectionName;


    /**
     * Requires subscription token to exist
     */
    modifier onlyExistentSubscription(uint256 tier, address subscriptionOwner) {
        _requireSubscriptionExists(tier, subscriptionOwner);
        _;
    }

    /**
     * Requires the specified tier to be active
     */
    modifier onlyActiveTiers(uint256 tier) {
        requireActiveTier(tier);
        _;
    }

    /**
     * Requires sender to be the merchant
     */
    modifier onlyMerchant() {
        requireMerchant();
        _;
    }

    /**
     * Initializes the contract by setting all the subscription parameters specified by the merchant.
     * @param paymentAmounts: prices of subscription tiers
     * @param tiersTotalSupply: total supply of each subscription tier
     * @param paymentFrequency: subscription payment frequency
     * @param merchant: subscription issuer; it will receive the subscription payments
     * @param baseUri: base URI for tiers metadata
     * @param startTimestamp: timestamp at which subscriptions minting will be enabled
     */
    constructor(string memory name, uint256[] memory paymentAmounts, int256[] memory tiersTotalSupply, uint256 paymentFrequency, address merchant, string memory baseUri, uint256 startTimestamp, address factoryAddress)
    ERC1155(baseUri)
    {   
        collectionName = name;
        _paymentAmounts = paymentAmounts;
        _paymentFrequency = paymentFrequency;
        _merchant = payable(merchant);
        _startTimestamp = startTimestamp;
        _nTiers = paymentAmounts.length;
        _factoryAddress = factoryAddress;

        ERC1155URIStorage._setBaseURI(baseUri);

        for (uint256 i = 0; i < _nTiers; i++){
            ERC1155URIStorage._setURI(i, Strings.toString(i));
            _activeTiers[i] = true;
            _tiersSupplies[i][0] = tiersTotalSupply[i];
            _tiersSupplies[i][1] = 0;
        }
    }

    /**
     * Changes the merchant to a new one.
     * Can be called only by current merchant.
     * @param to: new merchant
     */
    function transferMerchantRights(address to) external onlyMerchant() {
        emit MerchantTransfer(_merchant, to);
        _merchant = payable(to);
    }

    /**
     * Sets the price for the merchant rights transfer.
     * Can be called only by current merchant
     * @param price: price for the merchant rights transfer.
     */
    function setMerchantPrice(uint256 price) external onlyMerchant() {
        require(price > 0, "SubscriptionsCollection: use transferMerchantRights if the price is zero");
        _merchantPrice = price;
        onSale = true;
    }

    /**
     * Disables the sale of the collection.
     */
    function disableSale() external onlyMerchant() {
        onSale = false;
    }

    /**
     * Returns the price for the merchant rights transfer.
     */
    function getMerchantPrice() external view returns (uint256){
        require(onSale, "SubscriptionsCollection: merchant is not selling the collection");
        return _merchantPrice;
    }


    /**
     * Transfers merchant rights to the sender upon payment of the _merchantPrice.
     */
    function buyMerchantRights() external payable {
        require(onSale, "SubscriptionsCollection: merchant is not selling the collection");
        require(msg.value >= _merchantPrice, "SubscriptionsCollection: you must pay the price specified by the merchant");
        emit MerchantTransfer(_merchant, msg.sender);
        _merchant.transfer(msg.value);
        _merchant = payable(msg.sender);
    }
    
    /**
     * Creates new subscription tiers with the specified prices.
     * Can be called only by current merchant
     * @param paymentAmounts: new tiers' prices
     * @param tiersTotalSupply: new tiers' total supplies
     */
    function addTiers(uint256[] memory paymentAmounts, int256[] memory tiersTotalSupply) external onlyMerchant() returns (uint256[] memory){

        uint256[] memory newTiers = new uint256[](paymentAmounts.length);
        for(uint i = 0; i < paymentAmounts.length; i++) {
            _paymentAmounts.push(paymentAmounts[i]);
            uint256 newTier = i + _nTiers;
            //_tiersSupply.push(tiersSupply[i]);
            _tiersSupplies[newTier][0] = tiersTotalSupply[i];
            _tiersSupplies[newTier][1] = 0;
            _activeTiers[newTier] = true;
            newTiers[i] = newTier;
        }
        _nTiers += paymentAmounts.length;

        emit NewTiers(paymentAmounts, newTiers);

        return newTiers;
    }

    /**
     * Disables the specified subscription tiers.
     * Can be called only by current merchant
     * @param tiers: tiers to disable 
     */
    function disableTiers(uint256[] memory tiers) external onlyMerchant() {
        
        for(uint256 i = 0; i < tiers.length; i++) {
            require(getTierSupply(tiers[i], false) == 0, "SubscriptionsCollection: can't disable a tier with active subscriptions");
            _activeTiers[tiers[i]] = false;
        }

        emit TiersDisabled(tiers);
    }

    /**
     * Mints a subscription token to a specified address upon payment of the subscription price.
     * @param to: receiver of the token 
     * @param tier: subscription tier 
     */
    function mint(address to, uint256 tier) public payable onlyActiveTiers(tier){
        require(msg.value >= _paymentAmounts[tier], "SubscriptionsCollection: you must make the first payment to start a subscription");
        require(block.timestamp >= _startTimestamp, "SubscriptionsCollection: Minting has not started yet");
        require(to != address(0), "SubscriptionsCollection: cannot start subscription towards the zero address");

        //console.log("total supply: ", uint256(_tiersSupplies[tier][0]));
        //console.log("circulating supply: ", uint256(_tiersSupplies[tier][1]));
        require(_tiersSupplies[tier][0] == -1 || _tiersSupplies[tier][1] < _tiersSupplies[tier][0], "SubscriptionCollection: no more subscriptions available in this tier");
        _tiersSupplies[tier][1] += 1;

        _merchant.transfer(msg.value);
        
        uint256 deadline = block.timestamp + _paymentFrequency;
        SubscriptionInfo storage info =  _subscriptions[to][tier];
        info.deadline = deadline;
        
        emit SubscriptionUpdate(tier, to, deadline);
        
        _mint(to, tier, 1, "");    
    }


    /**
     * Updates subscription payment deadline upon payment of the tier price.
     * @param tier: subscription tier
     */
    function renewSubscription(uint256 tier) external onlyExistentSubscription(tier, msg.sender) onlyActiveTiers(tier) payable {
        require(msg.value >= _paymentAmounts[tier], "SubscriptionsCollection: you must pay the subscription price to renew your subscription");
        _merchant.transfer(msg.value);

        SubscriptionInfo storage info = _subscriptions[msg.sender][tier];

        info.deadline = info.deadline + _paymentFrequency;

        emit SubscriptionUpdate(tier, msg.sender, info.deadline);
    }

    /**
     * Terminates a subscription if its deadline is expired.
     * @param tier: subscription tier 
     * @param subscriptionOwner: subscription owner 
     */
    function endSubscription(uint256 tier, address subscriptionOwner) public onlyExistentSubscription(tier, subscriptionOwner){     
        SubscriptionInfo memory info =  _subscriptions[subscriptionOwner][tier];
                
        require(info.deadline < block.timestamp, "SubscriptionsCollection: Subscription not expired yet");
        
        delete _subscriptions[subscriptionOwner][tier];

        emit SubscriptionTermination(tier, subscriptionOwner);

        //if(_tiersSupplies[tier][0] >= 0) {
        _tiersSupplies[tier][1] -= 1;
        //}

        super._burn(subscriptionOwner, tier, 1);
    }

    /**
     * Approves subscription token transfer to an address, which will be able to transfer the token on the owner's behalf.
     * Can be called only by subscription owner 
     * @param to: address approved for transfer 
     * @param tier: subscription tier 
     */
    function approveSubscriptionTransfer(address to, uint256 tier) public onlyExistentSubscription(tier, msg.sender) onlyActiveTiers(tier) {
        address sender = _msgSender();
        _subscriptions[sender][tier].transferApproved = to;
        emit SubscriptionTokenTransferApproval(sender, to, tier);
    }
    
    /**
     * Returns the deadline for the payment of a subscription.
     * @param tier: subscription tier
     * @param subscriptionOwner: subscription owner
     */
    function getSubscriptionDeadline(uint256 tier, address subscriptionOwner) public view onlyExistentSubscription(tier, subscriptionOwner) returns (uint256 deadline) {
        return _subscriptions[subscriptionOwner][tier].deadline;
    }

    /**
     * Returns the address approved for the transfer of a subscription token.
     * @param tier: subscription tier
     * @param subscriptionOwner: subscription owner
     */
    function getSubscriptionTokenTransferApproved(uint256 tier, address subscriptionOwner) public view onlyExistentSubscription(tier, subscriptionOwner) returns (address approved) {
        return _subscriptions[subscriptionOwner][tier].transferApproved;
    }

    /**
     * Transfers a subscription token to ana address.
     * Can be called only by subscription owner or address approved for transfer
     * @param to: subscription receiver 
     * @param tier: subscription tier
     * @param subscriptionOwner: subscription owner 
     */
    function transferSubscriptionToken(address to, uint256 tier, address subscriptionOwner) public onlyExistentSubscription(tier, subscriptionOwner) onlyActiveTiers(tier) {
        SubscriptionInfo memory info = _subscriptions[subscriptionOwner][tier];
        address sender = _msgSender();
        
        require(sender == subscriptionOwner || sender == info.transferApproved, "SubscriptionsCollection: only Subscription receiver or approved address can transfer subscription token");
        require(to != _merchant, "SubscriptionsCollection: Cannot transfer to Subscription issuer");
        
        emit SubscriptionTokenTransfer(tier, subscriptionOwner, to);

        SubscriptionInfo storage newSub = _subscriptions[to][tier];
        newSub.deadline = info.deadline;

        delete _subscriptions[subscriptionOwner][tier];

        super._safeTransferFrom(subscriptionOwner, to, tier, 1, "");
    }
    
    /**
     * Throws if specified subscription does not exist.
     * @param tier: subscription tier 
     * @param subscriptionOwner: subscription owner 
     */
    function _requireSubscriptionExists(uint256 tier, address subscriptionOwner) private view {
         require(isExistentSubscription(tier, subscriptionOwner), "SubscriptionsCollection: Specified token must be an active subscription token");
    }

    /**
     * Throws if specified subscription is not in an active tier.
     * @param tier: subscription tier 
     */
    function requireActiveTier(uint256 tier) private view {
        require(isActiveTier(tier), "SubscriptionsCollection: specified subscription tier does not exist or is not active anymore");
    }

    /**
     * Throws if sender is not the merchant.
     */
    function requireMerchant() private view {
        require(isMerchant(), "SubscriptionsCollection: this function can be called only by the merchant");
    }
    
    /** @dev see {ERC1155._safeTransferFrom}
     */
    function _safeTransferFrom(address, address, uint256, uint256, bytes memory) internal pure override {
        revert("SubscriptionsCollection: cannot arbitrarily transfer subscription tokens; use transferSubscriptionToken function instead.");
    }

    /** @dev see {ERC1155._safeBatchTransferFrom}
     */
    function _safeBatchTransferFrom(address, address, uint256[] memory, uint256[] memory, bytes memory) internal pure override {
        revert("SubscriptionsCollection: cannot arbitrarily transfer subscription tokens; use transferSubscriptionToken function instead.");
    }

    /** @dev See {IERC165-supportsInterface}. */ 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Checks if a subscription token exists
     * @param tier: subscription tier
     * @param subscriptionOwner: subscription owner
     */
    function isExistentSubscription(uint256 tier, address subscriptionOwner) public view returns (bool) {
        return ERC1155.balanceOf(subscriptionOwner, tier) >= 1;
    }

    /**
     Checks if sender is merchant.
     */
    function isMerchant() private view returns (bool) {
        return msg.sender == _merchant;
    }

    /**
     * Checks if a tier is active.
     * @param tier: subscription tier 
     */
    function isActiveTier(uint256 tier) public view returns (bool) {
        return _activeTiers[tier];
    }

    /**
     * Returns the list of active tiers
     */
    function getActiveTiers() public view returns (uint256[] memory) {
        uint256[] memory tiers = new uint256[](getNActiveTiers());
        uint256 index = 0;
        for(uint256 tier = 0 ; tier < _nTiers ; tier++) {
            if(isActiveTier(tier)) {
                tiers[index] = tier; 
                index++;
            }
        }
        return tiers;
    }

    /**
     Returns merchant address;
     */
    function getMerchant() public view returns (address) {
        return _merchant;
    }

    /**
     Returns number of currently active subscription tiers;
     */
    function getNActiveTiers() public view returns (uint256 count) {
        for(uint256 i = 0 ; i < _nTiers ; i++) {
            if(isActiveTier(i)) {count++;}
        }
        return count;
    }

    /**
     Returns the total or circulating supply of a tier.
     @param totalOrCirculating: must be set to true for total supplies and false for circulating supplies
     @return supply: supply of specified tier
    */
    function getTierSupply(uint256 tier, bool totalOrCirculating) public view onlyActiveTiers(tier) returns (int256) {
        return totalOrCirculating ? _tiersSupplies[tier][0] : _tiersSupplies[tier][1];
    }

    /**
     Returns the total or circulating supply of all active tiers.
     @param totalOrCirculating: must be set to true for total supplies and false for circulating supplies
     @return tiers: Array of active tiers; 
     @return supplies: Supply of each active tier; neagative values for total supply mean infinite supply
     */
    function getTiersSupplies(bool totalOrCirculating) public view returns (uint256[] memory, int256[] memory) {
        
        uint256[] memory tiers = new uint256[](getNActiveTiers());
        int256[] memory supplies = new int256[](getNActiveTiers());
        uint256 index = 0;
        for(uint256 tier = 0 ; tier < _nTiers ; tier++) {
            if(isActiveTier(tier)) {
                tiers[index] = tier;
                supplies[index] = totalOrCirculating ? _tiersSupplies[tier][0] : _tiersSupplies[tier][1];
                index++;
            }
        }
        return (tiers, supplies);
    }

    /**
     Returns the total or circulating supply of a tier.
     @return supply: supply of specified tier
    */
    function getTierPrice(uint256 tier) public view onlyActiveTiers(tier) returns (uint256) {
        return _paymentAmounts[tier];
    }


    /**
     Returns the price of all active tiers.
     @return prices: Price of each active tier;
    */
    function getTiersPrices() public view returns (uint256[] memory, uint256[] memory) {
        
        uint256[] memory tiers = new uint256[](getNActiveTiers());
        uint256[] memory prices = new uint256[](getNActiveTiers());
        uint256 index = 0;
        for(uint256 tier = 0 ; tier < _nTiers ; tier++) {
            if(isActiveTier(tier)) {
                tiers[index] = tier;
                prices[index] = _paymentAmounts[tier];
                index++;
            }
        }
        return (tiers, prices);
    }

    /**
     * Destroys this contract sending its balance to the merchant.
     */
    function destroy() external {
        require(msg.sender == _factoryAddress, "SubscriptionsCollection: use the factory deleteCollection function to destroy a collection");
        
        uint256[] memory activeTiers = getActiveTiers();
        for(uint256 i = 0; i < activeTiers.length; i++){
            require(getTierSupply(activeTiers[i], false) == 0, "SubscriptionsCollection: cannot destroy a collection with active subscriptions");
        }
        selfdestruct(_merchant);
    }

}