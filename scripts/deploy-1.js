// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("ethers");
const hre = require("hardhat");

async function deploy(contractName, ...args) {
  // Deploy contract
  const Contract = await hre.ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(...args);
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  return contract;
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');
  console.log("HARDHAT_NETWORK", process.env.HARDHAT_NETWORK);
  const accounts = await hre.ethers.getSigners();

  const WETH = "0xa6fa4fb5f76172d178d61b04b0ecd319c5d1c0aa";
  const FREE_MINT_AMOUNT = 50;
  const MINT_PRICE = ethers.utils.parseEther('0.03');
  const MINT_SUPPLY = 1000;

  const contracts = {};

  contracts.nagaDaoNft = await deploy("NagaDaoNft");

  contracts.nagaSale1 = await deploy(
    "NagaSale1",
    contracts.nagaDaoNft.address,
    WETH,
    FREE_MINT_AMOUNT,
    MINT_PRICE,
    MINT_SUPPLY,
  );

  await contracts.nagaDaoNft.setAllowMinting(contracts.nagaSale1.address, true);

  return contracts;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = {deploy1: main};
