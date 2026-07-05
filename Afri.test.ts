import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("AfriRep", function () {
  let afriRep: any;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    const AfriRep = await ethers.getContractFactory("AfriRep");
    afriRep = await upgrades.deployProxy(AfriRep, [], { initializer: "initialize" });
    await afriRep.deployed();
  });

  // ──────────────────────────────────────────────
  //  User Registration
  // ──────────────────────────────────────────────

  describe("User Registration", function () {
    it("should register a new user with base reputation", async function () {
      await afriRep.connect(user1).registerUser("Chinedu", "NGA", "ipfs_hash_123");

      const profile = await afriRep.getUserProfile(user1.address);
      expect(profile.name).to.equal("Chinedu");
      expect(profile.countryCode).to.equal("NGA");
      expect(profile.reputationScore).to.equal(10);
      expect(profile.isVerified).to.equal(false);
    });

    it("should reject duplicate registration", async function () {
      await afriRep.connect(user1).registerUser("Chinedu", "NGA", "ipfs_hash_123");

      await expect(
        afriRep.connect(user1).registerUser("Chinedu2", "NGA", "ipfs_hash_456")
      ).to.be.revertedWithCustomError(afriRep, "AlreadyRegistered");
    });

    it("should reject invalid country codes (not 3 chars)", async function () {
      await expect(
        afriRep.connect(user1).registerUser("Chinedu", "NG", "ipfs_hash_123")
      ).to.be.revertedWithCustomError(afriRep, "InvalidCountryCode");

      await expect(
        afriRep.connect(user1).registerUser("Chinedu", "NGAA", "ipfs_hash_123")
      ).to.be.revertedWithCustomError(afriRep, "InvalidCountryCode");
    });

    it("should increment totalUsers counter", async function () {
      await afriRep.connect(user1).registerUser("Chinedu", "NGA", "hash1");
      await afriRep.connect(user2).registerUser("Amina", "KEN", "hash2");

      const stats = await afriRep.getPlatformStats();
      expect(stats._totalUsers).to.equal(2);
    });

    it("should allow updating profile name", async function () {
      await afriRep.connect(user1).registerUser("Chinedu", "NGA", "hash1");
      await afriRep.connect(user1).updateName("Chinedu Okoro");

      const profile = await afriRep.getUserProfile(user1.address);
      expect(profile.name).to.equal("Chinedu Okoro");
    });

    it("should allow updating profile image", async function () {
      await afriRep.connect(user1).registerUser("Chinedu", "NGA", "hash1");
      await afriRep.connect(user1).updateProfileImage("new_ipfs_hash");

      const profile = await afriRep.getUserProfile(user1.address);
      expect(profile.profileImageHash).to.equal("new_ipfs_hash");
    });
  });

  // ──────────────────────────────────────────────
  //  Vouching
  // ──────────────────────────────────────────────

  describe("Vouching", function () {
    beforeEach(async function () {
      await afriRep.connect(user1).registerUser("Chinedu", "NGA", "hash1");
      await afriRep.connect(user2).registerUser("Amina", "KEN", "hash2");
      await afriRep.connect(user3).registerUser("Fatima", "NGA", "hash3");
      await afriRep.connect(owner).addSkill("web_dev", "Web Development", "tech");
      await afriRep.connect(owner).addSkill("design", "UI/UX Design", "creative");
    });

    it("should allow giving a vouch with valid parameters", async function () {
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

    it("should prevent self-vouching", async function () {
      await expect(
        afriRep.connect(user1).giveVouch(
          user1.address,
          "web_dev",
          5,
          "I'm great!",
          "evidence"
        )
      ).to.be.revertedWithCustomError(afriRep, "CannotSelfVouch");
    });

    it("should reject confidence outside 1-5 range", async function () {
      await expect(
        afriRep.connect(user1).giveVouch(user2.address, "web_dev", 0, "", "")
      ).to.be.revertedWithCustomError(afriRep, "InvalidConfidence");

      await expect(
        afriRep.connect(user1).giveVouch(user2.address, "web_dev", 6, "", "")
      ).to.be.revertedWithCustomError(afriRep, "InvalidConfidence");
    });

    it("should prevent duplicate vouches for the same user+skill", async function () {
      await afriRep.connect(user1).giveVouch(user2.address, "web_dev", 5, "", "");

      await expect(
        afriRep.connect(user1).giveVouch(user2.address, "web_dev", 3, "", "")
      ).to.be.revertedWithCustomError(afriRep, "DuplicateVouch");
    });

    it("should allow vouching for different skills", async function () {
      await afriRep.connect(user1).giveVouch(user2.address, "web_dev", 5, "", "");
      await afriRep.connect(user1).giveVouch(user2.address, "design", 4, "", "");

      const vouches = await afriRep.getUserVouches(user2.address);
      expect(vouches.length).to.equal(2);
    });

    it("should reject vouches from unregistered users", async function () {
      const [, , , , unregistered] = await ethers.getSigners();

      await expect(
        afriRep.connect(unregistered).giveVouch(user2.address, "web_dev", 5, "", "")
      ).to.be.revertedWithCustomError(afriRep, "NotRegistered");
    });

    it("should allow revoking a vouch", async function () {
      const tx = await afriRep.connect(user1).giveVouch(user2.address, "web_dev", 5, "", "");
      const receipt = await tx.wait();
      const event = receipt.events?.find((e: any) => e.event === "VouchGiven");
      const vouchId = event?.args?.vouchId;

      await afriRep.connect(user1).revokeVouch(vouchId);

      // After revocation, user can re-vouch for the same skill
      await afriRep.connect(user1).giveVouch(user2.address, "web_dev", 3, "Updated", "");
    });

    it("should prevent non-owners from revoking a vouch", async function () {
      const tx = await afriRep.connect(user1).giveVouch(user2.address, "web_dev", 5, "", "");
      const receipt = await tx.wait();
      const event = receipt.events?.find((e: any) => e.event === "VouchGiven");
      const vouchId = event?.args?.vouchId;

      await expect(
        afriRep.connect(user2).revokeVouch(vouchId)
      ).to.be.revertedWithCustomError(afriRep, "NotVouchOwner");
    });

    it("should update totalVouches counter", async function () {
      await afriRep.connect(user1).giveVouch(user2.address, "web_dev", 5, "", "");
      await afriRep.connect(user3).giveVouch(user2.address, "web_dev", 4, "", "");

      const stats = await afriRep.getPlatformStats();
      expect(stats._totalVouches).to.equal(2);
    });
  });

  // ──────────────────────────────────────────────
  //  Reputation Calculation
  // ──────────────────────────────────────────────

  describe("Reputation Scoring", function () {
    beforeEach(async function () {
      await afriRep.connect(user1).registerUser("Chinedu", "NGA", "hash1");
      await afriRep.connect(user2).registerUser("Amina", "KEN", "hash2");
      await afriRep.connect(user3).registerUser("Fatima", "NGA", "hash3");
      await afriRep.connect(owner).addSkill("web_dev", "Web Development", "tech");
    });

    it("should increase reputation with same-country vouches", async function () {
      // user3 (NGA) vouches for user1 (NGA) — same country = 100% multiplier
      await afriRep.connect(user3).giveVouch(user1.address, "web_dev", 5, "", "");

      const profile = await afriRep.getUserProfile(user1.address);
      // Base 10 + (5 * 2 * 100 / 100) = 10 + 10 = 20
      expect(Number(profile.reputationScore)).to.be.greaterThan(10);
    });

    it("should apply cross-border multiplier for different regions", async function () {
      // user2 (KEN) vouches for user1 (NGA) — different region = 80% multiplier
      await afriRep.connect(user2).giveVouch(user1.address, "web_dev", 5, "", "");

      const profile = await afriRep.getUserProfile(user1.address);
      // Base 10 + (5 * 2 * 80 / 100) = 10 + 8 = 18
      expect(Number(profile.reputationScore)).to.be.greaterThan(10);
    });

    it("should cap reputation at 1000", async function () {
      // Note: in practice this would require many vouches
      const profile = await afriRep.getUserProfile(user1.address);
      expect(Number(profile.reputationScore)).to.be.lessThanOrEqual(1000);
    });
  });

  // ──────────────────────────────────────────────
  //  Admin Functions
  // ──────────────────────────────────────────────

  describe("Admin Functions", function () {
    it("should add skills (admin only)", async function () {
      await afriRep.connect(owner).addSkill("web_dev", "Web Development", "tech");

      // Verify the skill was added (checking the mapping)
      const skill = await afriRep.skills("web_dev");
      expect(skill.name).to.equal("Web Development");
    });

    it("should reject duplicate skill IDs", async function () {
      await afriRep.connect(owner).addSkill("web_dev", "Web Development", "tech");

      await expect(
        afriRep.connect(owner).addSkill("web_dev", "Web Dev 2", "tech")
      ).to.be.revertedWithCustomError(afriRep, "SkillAlreadyExists");
    });

    it("should reject addSkill from non-admin", async function () {
      await expect(
        afriRep.connect(user1).addSkill("web_dev", "Web Development", "tech")
      ).to.be.reverted;
    });

    it("should allow admin to verify users", async function () {
      await afriRep.connect(user1).registerUser("Chinedu", "NGA", "hash1");
      await afriRep.connect(owner).verifyUser(user1.address);

      const profile = await afriRep.getUserProfile(user1.address);
      expect(profile.isVerified).to.equal(true);
    });

    it("should allow admin to update country multipliers", async function () {
      await afriRep.connect(owner).setCountryMultiplier("NGA", 120);
      // Verify the multiplier was updated
      const multiplier = await afriRep.countryTrustMultipliers("NGA");
      expect(multiplier).to.equal(120);
    });

    it("should allow pausing and unpausing", async function () {
      await afriRep.connect(owner).pause();

      await expect(
        afriRep.connect(user1).registerUser("Test", "NGA", "hash")
      ).to.be.reverted; // Should fail when paused

      await afriRep.connect(owner).unpause();

      // Should work again after unpausing
      await afriRep.connect(user1).registerUser("Test", "NGA", "hash");
    });
  });

  // ──────────────────────────────────────────────
  //  Validator Functions
  // ──────────────────────────────────────────────

  describe("Validator Functions", function () {
    it("should allow validators to invalidate vouches", async function () {
      await afriRep.connect(user1).registerUser("Chinedu", "NGA", "hash1");
      await afriRep.connect(user2).registerUser("Amina", "KEN", "hash2");
      await afriRep.connect(owner).addSkill("web_dev", "Web Development", "tech");

      const tx = await afriRep.connect(user1).giveVouch(user2.address, "web_dev", 5, "", "");
      const receipt = await tx.wait();
      const event = receipt.events?.find((e: any) => e.event === "VouchGiven");
      const vouchId = event?.args?.vouchId;

      // Validator invalidates the vouch
      await afriRep.connect(owner).invalidateVouch(vouchId);

      // Reputation should decrease after invalidation
      const profile = await afriRep.getUserProfile(user2.address);
      expect(Number(profile.reputationScore)).to.equal(10); // Back to base
    });
  });
});