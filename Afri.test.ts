import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("AfriRep", function () {
  let afriRep: any;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    
    const AfriRep = await ethers.getContractFactory("AfriRep");
    afriRep = await upgrades.deployProxy(AfriRep, [], { initializer: 'initialize' });
    await afriRep.deployed();
  });

  it("Should register a new user", async function () {
    await afriRep.connect(user1).registerUser("Chinedu", "NGA", "ipfs_hash_123");
    
    const profile = await afriRep.getUserProfile(user1.address);
    expect(profile.name).to.equal("Chinedu");
    expect(profile.countryCode).to.equal("NGA");
    expect(profile.reputationScore).to.equal(10);
  });

  it("Should allow giving vouches", async function () {
    // Register both users first
    await afriRep.connect(user1).registerUser("Chinedu", "NGA", "ipfs_hash_123");
    await afriRep.connect(user2).registerUser("Amina", "KEN", "ipfs_hash_456");
    
    // Add a skill first
    await afriRep.connect(owner).addSkill("web_dev", "Web Development", "tech");
    
    // Give vouch
    await afriRep.connect(user1).giveVouch(
      user2.address,
      "web_dev",
      5,
      "Excellent developer!",
      "ipfs_evidence_hash"
    );
    
    const vouches = await afriRep.getUserVouches(user2.address);
    expect(vouches.length).to.equal(1);
  });

  it("Should calculate reputation with cross-border adjustments", async function () {
    await afriRep.connect(user1).registerUser("Chinedu", "NGA", "ipfs_hash_123");
    await afriRep.connect(user2).registerUser("Amina", "KEN", "ipfs_hash_456");
    
    
    
   
    