const hre = require("hardhat");
async function main() {
  const GridFactory = await hre.ethers.getContractFactory("NexusEnergyGrid");
  const energyGrid = await GridFactory.deploy();
  await energyGrid.deployed();
  console.log("-> Energy Grid Protocol active at:", energyGrid.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
