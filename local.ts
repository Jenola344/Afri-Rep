import { ethers, upgrades } from "hardhat";

async function main() {
  console.log("🚀 Deploying Afri Rep contracts to local network...");
  
  // Deploy AfriRep core contract
  const AfriRep = await ethers.getContractFactory("AfriRep");
  const afriRep = await upgrades.deployProxy(AfriRep, [], { initializer: 'initialize' });
  
  await afriRep.deployed();
  console.log("✅ AfriRep deployed to:", afriRep.address);
  
  // Deploy AfriStablecoin
  const AfriStablecoin = await ethers.getContractFactory("AfriStablecoin");
  const afriStablecoin = await AfriStablecoin.deploy();
  
  await afriStablecoin.deployed();
  console.log("✅ AfriStablecoin deployed to:", afriStablecoin.address);
  
  // Deploy AjoCircle with AfriRep address
  const AjoCircle = await ethers.getContractFactory("AjoCircle");
  const ajoCircle = await AjoCircle.deploy(afriRep.address);
  
  await ajoCircle.deployed();
  console.log("✅ AjoCircle deployed to:", ajoCircle.address);
  
  console.log("🎉 All contracts deployed successfully!");
  console.log("📝 Contract addresses:");
  console.log("AfriRep:", afriRep.address);
  console.log("AfriStablecoin:", afriStablecoin.address);
  console.log("AjoCircle:", ajoCircle.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});