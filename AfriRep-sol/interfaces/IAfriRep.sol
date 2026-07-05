// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IAfriRep — Interface for the Afri Rep Reputation Protocol
 * @author Afri Rep Contributors
 * @notice Public interface consumed by downstream contracts (InnerCircleDAO,
 *         stablecoin gating, opportunity marketplace, etc.).
 */
interface IAfriRep {
    // ──────────────────────────────────────────────
    //  Events
    // ──────────────────────────────────────────────

    /// @notice Emitted when a new user registers.
    event UserRegistered(address indexed user, string name, string countryCode, uint256 timestamp);

    /// @notice Emitted when a vouch is given.
    event VouchGiven(bytes32 indexed vouchId, address indexed from, address indexed to, string skillId, uint256 confidence);

    /// @notice Emitted when a vouch is revoked by its creator.
    event VouchRevoked(bytes32 indexed vouchId, address indexed revoker);

    /// @notice Emitted when a vouch is invalidated by a validator.
    event VouchInvalidated(bytes32 indexed vouchId, address indexed invalidator);

    /// @notice Emitted when a user's reputation changes.
    event ReputationUpdated(address indexed user, uint256 oldScore, uint256 newScore);

    /// @notice Emitted when a new skill is added.
    event SkillAdded(string skillId, string name, string category);

    /// @notice Emitted when a country multiplier is changed.
    event CountryMultiplierUpdated(string countryCode, uint256 oldMultiplier, uint256 newMultiplier);

    /// @notice Emitted when a user's profile field is updated.
    event ProfileUpdated(address indexed user, string field);

    /// @notice Emitted when a user is verified.
    event UserVerified(address indexed user, address indexed verifier);

    // ──────────────────────────────────────────────
    //  User Registration & Profile
    // ──────────────────────────────────────────────

    /**
     * @notice Register a new user.
     * @param _name             Display name.
     * @param _countryCode      ISO 3166-1 alpha-3 country code.
     * @param _profileImageHash IPFS CID of profile image.
     */
    function registerUser(
        string memory _name,
        string memory _countryCode,
        string memory _profileImageHash
    ) external;

    /**
     * @notice Update profile image.
     * @param _newHash New IPFS CID.
     */
    function updateProfileImage(string memory _newHash) external;

    /**
     * @notice Update display name.
     * @param _newName New name.
     */
    function updateName(string memory _newName) external;

    // ──────────────────────────────────────────────
    //  Vouching
    // ──────────────────────────────────────────────

    /**
     * @notice Give a vouch to another user.
     * @param _to           Recipient address.
     * @param _skillId      Skill being endorsed.
     * @param _confidence   Confidence level (1–5).
     * @param _comment      Optional comment.
     * @param _evidenceHash IPFS CID of evidence.
     * @return vouchId      Unique vouch identifier.
     */
    function giveVouch(
        address _to,
        string memory _skillId,
        uint256 _confidence,
        string memory _comment,
        string memory _evidenceHash
    ) external returns (bytes32);

    /**
     * @notice Revoke a vouch you previously gave.
     * @param _vouchId ID of the vouch to revoke.
     */
    function revokeVouch(bytes32 _vouchId) external;

    // ──────────────────────────────────────────────
    //  Admin
    // ──────────────────────────────────────────────

    /**
     * @notice Add a new skill to the registry (admin only).
     * @param _skillId  Unique skill identifier.
     * @param _name     Skill display name.
     * @param _category Skill category.
     */
    function addSkill(
        string memory _skillId,
        string memory _name,
        string memory _category
    ) external;

    /**
     * @notice Update a country's trust multiplier (admin only).
     * @param _countryCode ISO 3166-1 alpha-3 code.
     * @param _multiplier  New multiplier (100 = neutral).
     */
    function setCountryMultiplier(
        string memory _countryCode,
        uint256 _multiplier
    ) external;

    /**
     * @notice Verify a user's identity (validator only).
     * @param _user Address to verify.
     */
    function verifyUser(address _user) external;

    // ──────────────────────────────────────────────
    //  View Functions
    // ──────────────────────────────────────────────

    /**
     * @notice Retrieve a user's public profile.
     * @param _user Address of the user.
     * @return name             Display name.
     * @return countryCode      ISO country code.
     * @return reputationScore  Current reputation (0–1000).
     * @return isVerified       Identity verification status.
     * @return profileImageHash IPFS CID.
     * @return lastActivity     Timestamp of last activity.
     */
    function getUserProfile(address _user)
        external
        view
        returns (
            string memory name,
            string memory countryCode,
            uint256 reputationScore,
            bool isVerified,
            string memory profileImageHash,
            uint256 lastActivity
        );

    /**
     * @notice Get all vouch IDs received by a user.
     * @param _user Address of the user.
     * @return Array of vouch ID hashes.
     */
    function getUserVouches(address _user)
        external
        view
        returns (bytes32[] memory);

    /**
     * @notice Get all vouch IDs given by a user.
     * @param _user Address of the user.
     * @return Array of vouch ID hashes.
     */
    function getUserVouchesGiven(address _user)
        external
        view
        returns (bytes32[] memory);

    /**
     * @notice Get platform-wide statistics.
     * @return totalUsers   Total registered users.
     * @return totalVouches Total vouches created.
     */
    function getPlatformStats()
        external
        view
        returns (uint256 totalUsers, uint256 totalVouches);
}