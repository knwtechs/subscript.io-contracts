const { ethers } = require("hardhat");
const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const time = require("@nomicfoundation/hardhat-network-helpers").time;


describe("SubscriptionsCollection contract", function () {

  //Deploys the contract
  async function deployFixture() {
    const factory = await ethers.getContractFactory("SubscriptionsFactory");
    const [owner, addr1, addr2] = await ethers.getSigners();

    const hardhatFactory = await factory.deploy();
    await hardhatFactory.deployed();

    var startTimestamp = 0;
    const collectionAddress = await hardhatFactory.callStatic.createCollection("TestName", [10, 20], [-1, 5], 3000, owner.address, "TestURI", startTimestamp);
    await hardhatFactory.createCollection("TestName", [10, 20], [-1, 5], 300, owner.address, "TestURI", startTimestamp);
    const SubscriptionsCollection = await ethers.getContractFactory("SubscriptionsCollection");
    const collection = SubscriptionsCollection.attach(collectionAddress);
    return {collection, owner, addr1, addr2};
  }

  //Deploys the contract and mints two tokens
  async function deployAndMintFixture() {
    const factory = await ethers.getContractFactory("SubscriptionsFactory");
    const [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();

    const hardhatFactory = await factory.deploy();
    await hardhatFactory.deployed();

    var startTimestamp = 0;
    const collectionAddress = await hardhatFactory.callStatic.createCollection("TestName", [10, 20], [-1, 5], 3000, owner.address, "TestURI", startTimestamp);
    await hardhatFactory.createCollection("TestName", [10, 20], [-1, 5], 300, owner.address, "TestURI", startTimestamp);
    const SubscriptionsCollection = await ethers.getContractFactory("SubscriptionsCollection");
    const collection = SubscriptionsCollection.attach(collectionAddress);

    await collection.connect(addr1).mint(addr1.address, 0, {value: 10});
    await collection.connect(addr2).mint(addr2.address, 1, {value: 20});
 
    

    return { collection, owner, addr1, addr2, addr3, addr4, addr5, hardhatFactory };
  }



  describe("Deployment", function () {

    it("Should deploy", async function () {   
      await loadFixture(deployFixture);
    });

    it("Should mint 3 tokens per address", async function () {      
      const { collection, addr1, addr2 } = await loadFixture(deployAndMintFixture);


      expect(await collection.balanceOf(addr1.address, 0)).to.equal(1);
      expect(await collection.balanceOf(addr2.address, 1)).to.equal(1);
    });

  });



  describe("Subscription start", function () {

    it("Accounts should not be able to start subscription without paying the correct tier price", async function () {
      const { collection, addr1 } = await loadFixture(deployFixture);

      await expect(collection.connect(addr1).mint(addr1.address, 1, {value: 10}))
        .to.be.revertedWith("SubscriptionsCollection: you must make the first payment to start a subscription");
    });

    it("Accounts should be able to start subscription paying the correct tier price", async function () {
      const { collection, addr1 } = await loadFixture(deployFixture);

      await collection.connect(addr1).mint(addr1.address, 1, {value: 20});

      expect(await collection.balanceOf(addr1.address, 1)).to.equal(1);
    });

    it("Should not start subscription towards the zero address", async function () {
      const { collection, owner, addr1, addr2 } = await loadFixture(deployFixture);

      await expect(collection.connect(addr1)
        .mint(ethers.constants.AddressZero, 1, {value: 20}))
        .to.be.revertedWith("SubscriptionsCollection: cannot start subscription towards the zero address");
    });

    it("Should not mint new tokens if the total supply has been reached", async function () {
      const { collection, owner, addr1, addr2 } = await loadFixture(deployFixture);

      for (let i = 1; i <= 5; i++) {
        await collection.connect(addr1).mint(addr1.address, 1, {value: 20});
      };

      await expect(collection.connect(addr1)
        .mint(addr1.address, 1, {value: 20}))
        .to.be.revertedWith("SubscriptionCollection: no more subscriptions available in this tier");
      });
  });

  

  describe("Subscription installment deadline update", function () {

    it("Accounts should not be able to renew their subscription without paying the correct tier price", async function () {
      const { collection, addr2 } = await loadFixture(deployAndMintFixture);

      await expect(collection.connect(addr2).renewSubscription(1, {value: 10}))
        .to.be.revertedWith("SubscriptionsCollection: you must pay the subscription price to renew your subscription");
    });
    
    it("Accounts should be able to renew their subscription paying the correct tier price", async function () {
      const { collection, addr2 } = await loadFixture(deployAndMintFixture);

      let oldDeadline = await collection.getSubscriptionDeadline(1, addr2.address);

      await expect(await collection.connect(addr2).renewSubscription(1, {value: 20}));

      expect(await collection.getSubscriptionDeadline(1, addr2.address)).to.greaterThan(oldDeadline);

    })
  });



  describe("Subscription termination", function () {

    it("Subscription should not be terminated before installment deadline", async function () {
      const { collection, addr1 } = await loadFixture(deployAndMintFixture);

      await expect(collection.endSubscription(0, addr1.address)).to.be.revertedWith("SubscriptionsCollection: Subscription not expired yet");
    });

    it("Any address should be able to end Subscription after installment deadline; token should be returned", async function () {
      const { collection, owner, addr1, addr2 } = await loadFixture(deployAndMintFixture);
      
      await time.increase(3000);
      
      await expect(collection.endSubscription(0, addr1.address));

      expect(await collection.isExistentSubscription(0, addr1.address)).to.false;
    });

  });



  describe("Transfers during subscription", function () {

    it("Subscription token should be transferable by subscription owner. Subscription should still be endable after deadline", async function () {
      const { collection, owner, addr1, addr3 } = await loadFixture(deployAndMintFixture);

      await collection.connect(addr1).transferSubscriptionToken(addr3.address, 0, addr1.address);

      expect(await collection.balanceOf(addr1.address, 0)).to.equal(0);
      expect(await collection.balanceOf(addr3.address, 0)).to.equal(1);

      await time.increase(3000);

      await collection.endSubscription(0, addr3.address);

      //expect(await collection.balanceOf(owner.address, 0)).to.equal(1);
      expect(await collection.balanceOf(addr3.address, 0)).to.equal(0);

    });

    it("Subscriptioned token should be transferable by address approved by subscription owner", async function () {
      const { collection, owner, addr1, addr2, addr3 } = await loadFixture(deployAndMintFixture);

      await collection.connect(addr1).approveSubscriptionTransfer(addr2.address, 0);
      await collection.connect(addr2).transferSubscriptionToken(addr3.address, 0, addr1.address);

      expect(await collection.balanceOf(addr1.address, 0)).to.equal(0);
      expect(await collection.balanceOf(addr3.address, 0)).to.equal(1);

      await time.increase(3000);

      await collection.endSubscription(0, addr3.address);

      expect(await collection.balanceOf(addr3.address, 0)).to.equal(0);

    });

  });


  describe("Merchant operations", function () {

    it("Merchant should be able to nominate a new merchant", async function () {
      const { collection, owner, addr3 } = await loadFixture(deployAndMintFixture);

      await collection.connect(owner).transferMerchantRights(addr3.address);

      expect(await collection.getMerchant()).to.equal(addr3.address);
    });

    it("Merchant should be able to propose a price for transfering merchant rights; any account should be able to acquire merchant rights paying the agreed price", async function () {
      const { collection, owner, addr3 } = await loadFixture(deployAndMintFixture);

      await collection.connect(owner).setMerchantPrice(1000);

      await collection.connect(addr3).buyMerchantRights({value: 1000});

      expect(await collection.getMerchant()).to.equal(addr3.address);
    });

    
    it("Merchant should be able to disable the collection sale after proposing a price", async function () {
      const { collection, owner, addr3 } = await loadFixture(deployAndMintFixture);

      await collection.connect(owner).setMerchantPrice(1000);

      await collection.connect(owner).disableSale();

      await expect(collection.connect(addr3).buyMerchantRights({value: 1000}))
        .to.be.revertedWith("SubscriptionsCollection: merchant is not selling the collection");

      expect(await collection.getMerchant()).to.equal(owner.address);
    });

    it("Merchant should be able to add subscription tiers", async function () {
      const { collection, owner, addr3 } = await loadFixture(deployAndMintFixture);

      await collection.connect(owner).addTiers([30], [100]);

      await collection.connect(addr3).mint(addr3.address, 2, {value : 30});

      expect(await collection.balanceOf(addr3.address, 2)).to.equal(1);
    });

     
    it("Merchant should be able to disable subscription tiers. New subscriptions should not be started in the removed tiers", async function () {
      const { collection, owner, addr2, addr3 } = await loadFixture(deployAndMintFixture);

      await time.increase(3500);

      await collection.connect(owner).endSubscription(1, addr2.address)

      await collection.connect(owner).disableTiers([1]);

      await expect(collection.connect(addr3).mint(addr3.address, 2, {value : 30}))
        .to.be.revertedWith("SubscriptionsCollection: specified subscription tier does not exist or is not active anymore");

    });

    
    it("Merchant should be able to delete a collection", async function () {
      const { collection, owner, addr1, addr2, hardhatFactory } = await loadFixture(deployAndMintFixture);

      await time.increase(3500);

      await collection.connect(owner).endSubscription(0, addr1.address);

      await collection.connect(owner).endSubscription(1, addr2.address);
      
      await hardhatFactory.connect(owner).deleteCollection(collection.address);
    });
    
    it("Non-merchant addresses should not be able to delete a collection", async function () {
      const { collection, owner, addr1, hardhatFactory } = await loadFixture(deployAndMintFixture);

      await hardhatFactory.connect(addr1).deleteCollection(collection.address);

      expect(await collection.getMerchant()).to.equal(owner.address);
    });
  });
  
  

  describe("Transfers", function () {

    it("Subscription token should not be transferable outside transferSubscriptionToken function", async function () {
      const { collection, owner, addr1, addr2, addr3 } = await loadFixture(deployAndMintFixture);

      await expect(collection.connect(addr1).safeTransferFrom(addr1.address, addr3.address, 0, 1, "0x00")).to.be.revertedWith("SubscriptionsCollection: cannot arbitrarily transfer subscription tokens; use transferSubscriptionToken function instead.");
    });

  });

  describe("Miscellaneous", function () {

    it("Subscription operations should not interfere with each other", async function () {
      const { collection, owner, addr1, addr2, addr3, addr4, addr5 } = await loadFixture(deployAndMintFixture);
      
      var timestamp = Date.now();

      let oldDeadline = await collection.getSubscriptionDeadline(1, addr2.address);

      await collection.connect(addr1).renewSubscription(0, {value : 10});

      expect(await collection.getSubscriptionDeadline(0, addr1.address)).to.greaterThan(oldDeadline);

      
      await collection.connect(addr1).approveSubscriptionTransfer(owner.address, 0);
      await collection.connect(owner).transferSubscriptionToken(addr3.address, 0, addr1.address); 
      expect(await collection.balanceOf(addr3.address, 0)).to.equal(1);

      await expect(collection.connect(addr1).approveSubscriptionTransfer(owner.address, 0)).to.be.revertedWith("SubscriptionsCollection: Specified token must be an active subscription token");

      await time.increase(6000);
      await collection.endSubscription(0, addr3.address);
    });

  });


});