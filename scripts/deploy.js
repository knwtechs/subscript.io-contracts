// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.

/** 
const hre = require("hardhat");

async function main() {

  const subscriptionsFactory = await hre.ethers.deployContract("SubscriptionsFactory");

  await subscriptionsFactory.deployed();

  console.log(
    `SubscriptionsFactory deployed at ${subscriptionsFactory.address}` //to ${subscriptionsFactory.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
*/

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  
  const contract = await ethers.deployContract("SubscriptionsFactory");
  console.log(contract)

  console.log("Contract address:", await contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });