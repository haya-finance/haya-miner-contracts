import hre from "hardhat";

const { ethers, run, defender, upgrades } = require("hardhat");

require("dotenv").config();

async function main() {
  const CONTRACTS_OWNER = process.env.CONTRACTS_OWNER as string;
  const OUTPUT_FACTOR = 1;
  const HAYA_TOKEN_POOL = "";
  const MINER_CONTRACT = "";
  const launchConfig = [
    OUTPUT_FACTOR,
    MINER_CONTRACT,
    HAYA_TOKEN_POOL,
    CONTRACTS_OWNER,
    0,
    0,
  ];

  const MinerStakingContract = await ethers.getContractFactory(
    "MinerStakingContract"
  );
  console.log("Deploying MinerStakingContract...");

  const minerStakingContract = await upgrades.deployProxy(
    MinerStakingContract,
    [launchConfig],
    {
      initializer: "initialize",
    }
  );
  await minerStakingContract.waitForDeployment();

  const minerStakingAdress = await minerStakingContract.getAddress();
  console.log("MinerStakingContract deployed to:", minerStakingAdress);
  try {
    await new Promise((resolve) => setTimeout(resolve, 20000));
    await run("verify:verify", {
      address: minerStakingAdress,
    });
  } catch (error) {
    console.log(error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
