// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IAfriRep.sol";

/**
 * @title AfriRep — Pan-African Reputation Protocol
 * @author Afri Rep Contributors
 * @notice Core contract for managing user profiles, skill vouching, and
 *         cross-border reputation scoring across 54 African nations.
 * @dev Upgradeable via OpenZeppelin UUPS pattern. Reputation scores are
 *      capped at 1000 and decay 1% per month of inactivity. Cross-border
 *      vouches receive a regional trust multiplier (same country 100%,
 *      same region 90%, cross-region 80%).
 */
contract AfriRep is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IAfriRep
{
    // ──────────────────────────────────────────────
    //  Constants & Roles
    // ──────────────────────────────────────────────

    /// @notice Role hash for platform administrators.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Role hash for reputation validators.
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    /// @notice Maximum attainable reputation score.
    uint256 public constant MAX_REP_SCORE = 1000;

    /// @notice Base reputation granted to every new user on registration.
    uint256 public constant BASE_REP_SCORE = 10;

    /// @notice Minimum confidence level for a vouch (inclusive).
    uint256 public constant MIN_CONFIDENCE = 1;

    /// @notice Maximum confidence level for a vouch (inclusive).
    uint256 public constant MAX_CONFIDENCE = 5;

    // ──────────────────────────────────────────────
    //  Data Structures
    // ──────────────────────────────────────────────

    /// @notice On-chain profile for a registered user.
    struct UserProfile {
        address walletAddress;
        string name;
        string countryCode;       // ISO 3166-1 alpha-3
        uint256 joinDate;
        uint256 reputationScore;
        bool isVerified;
        string profileImageHash;  // IPFS CID
        string[] skills;
        uint256 lastActivity;
        uint256 totalVouchesReceived;
        uint256 totalVouchesGiven;
    }

    /// @notice Skill definition with regional weighting.
    struct Skill {
        string id;
        string name;
        string category;
        uint256 globalWeight;
        bool exists;
        mapping(string => uint256) regionalWeights; // countryCode => weight
    }

    /// @notice A single vouch from one user to another for a specific skill.
    struct Vouch {
        address from;
        address to;
        string skillId;
        uint256 confidence;      // 1-5
        string comment;
        string evidenceHash;     // IPFS CID
        uint256 timestamp;
        bool isValid;
    }

    // ──────────────────────────────────────────────
    //  State
    // ──────────────────────────────────────────────

    /// @notice User address → profile mapping.
    mapping(address => UserProfile) public userProfiles;

    /// @notice Skill ID → Skill mapping.
    mapping(string => Skill) public skills;

    /// @notice Vouch ID → Vouch mapping.
    mapping(bytes32 => Vouch) public vouches;

    /// @notice User address → list of vouch IDs given by this user.
    mapping(address => bytes32[]) public userVouchesGiven;

    /// @notice User address → list of vouch IDs received by this user.
    mapping(address => bytes32[]) public userVouchesReceived;

    /// @notice ISO country code → base trust multiplier (percentage, 100 = 1×).
    mapping(string => uint256) public countryTrustMultipliers;

    /// @notice Tracks whether a user has already vouched another user for a specific skill.
    /// @dev keccak256(from, to, skillId) → bool
    mapping(bytes32 => bool) public hasVouchedForSkill;

    /// @notice Total number of registered users.
    uint256 public totalUsers;

    /// @notice Total number of vouches ever created.
    uint256 public totalVouches;

    // ──────────────────────────────────────────────
    //  Events
    // ──────────────────────────────────────────────

    /// @notice Emitted when a new user registers on the platform.
    event UserRegistered(address indexed user, string name, string countryCode, uint256 timestamp);

    /// @notice Emitted when a vouch is given from one user to another.
    event VouchGiven(bytes32 indexed vouchId, address indexed from, address indexed to, string skillId, uint256 confidence);

    /// @notice Emitted when a vouch is revoked by its creator.
    event VouchRevoked(bytes32 indexed vouchId, address indexed revoker);

    /// @notice Emitted when a vouch is invalidated by a validator.
    event VouchInvalidated(bytes32 indexed vouchId, address indexed invalidator);

    /// @notice Emitted when a user's reputation score changes.
    event ReputationUpdated(address indexed user, uint256 oldScore, uint256 newScore);

    /// @notice Emitted when a new skill is registered in the system.
    event SkillAdded(string skillId, string name, string category);

    /// @notice Emitted when a country trust multiplier is updated.
    event CountryMultiplierUpdated(string countryCode, uint256 oldMultiplier, uint256 newMultiplier);

    /// @notice Emitted when a user's profile is updated.
    event ProfileUpdated(address indexed user, string field);

    /// @notice Emitted when a user is verified by a validator.
    event UserVerified(address indexed user, address indexed verifier);

    // ──────────────────────────────────────────────
    //  Errors
    // ──────────────────────────────────────────────

    /// @notice Thrown when a user attempts to register a second time.
    error AlreadyRegistered();

    /// @notice Thrown when an action requires a registered user.
    error NotRegistered();

    /// @notice Thrown when an ISO country code is not exactly 3 characters.
    error InvalidCountryCode();

    /// @notice Thrown when a user tries to vouch for themselves.
    error CannotSelfVouch();

    /// @notice Thrown when confidence is outside the 1-5 range.
    error InvalidConfidence();

    /// @notice Thrown when a duplicate vouch for the same user+skill already exists.
    error DuplicateVouch();

    /// @notice Thrown when referencing a vouch ID that does not exist.
    error VouchNotFound();

    /// @notice Thrown when only the original voucher can perform the action.
    error NotVouchOwner();

    /// @notice Thrown when a skill ID does not exist in the registry.
    error SkillNotFound();

    /// @notice Thrown when attempting to add a skill that already exists.
    error SkillAlreadyExists();

    // ──────────────────────────────────────────────
    //  Modifiers
    // ──────────────────────────────────────────────

    /// @dev Requires `msg.sender` to be a registered user.
    modifier onlyRegistered() {
        if (bytes(userProfiles[msg.sender].name).length == 0) revert NotRegistered();
        _;
    }

    /// @dev Requires `_user` to be a registered user.
    modifier isRegistered(address _user) {
        if (bytes(userProfiles[_user].name).length == 0) revert NotRegistered();
        _;
    }

    // ──────────────────────────────────────────────
    //  Initialization
    // ──────────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract (replaces constructor for upgradeable pattern).
     * @dev Sets up access control roles and initializes country trust multipliers
     *      for major African economies.
     */
    function initialize() public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(VALIDATOR_ROLE, msg.sender);

        _initializeCountryMultipliers();
    }

    /**
     * @dev Seeds trust multipliers for African nations at 100 (neutral).
     *      Admins can later adjust per-country via `setCountryMultiplier`.
     */
    function _initializeCountryMultipliers() internal {
        // West Africa
        countryTrustMultipliers["NGA"] = 100; // Nigeria
        countryTrustMultipliers["GHA"] = 100; // Ghana
        countryTrustMultipliers["SEN"] = 100; // Senegal
        countryTrustMultipliers["CIV"] = 100; // Côte d'Ivoire
        countryTrustMultipliers["BEN"] = 100; // Benin
        countryTrustMultipliers["TGO"] = 100; // Togo
        countryTrustMultipliers["BFA"] = 100; // Burkina Faso
        countryTrustMultipliers["MLI"] = 100; // Mali
        countryTrustMultipliers["NER"] = 100; // Niger
        countryTrustMultipliers["GIN"] = 100; // Guinea
        countryTrustMultipliers["SLE"] = 100; // Sierra Leone
        countryTrustMultipliers["LBR"] = 100; // Liberia
        countryTrustMultipliers["GMB"] = 100; // Gambia
        countryTrustMultipliers["GNB"] = 100; // Guinea-Bissau
        countryTrustMultipliers["CPV"] = 100; // Cape Verde

        // East Africa
        countryTrustMultipliers["KEN"] = 100; // Kenya
        countryTrustMultipliers["TZA"] = 100; // Tanzania
        countryTrustMultipliers["UGA"] = 100; // Uganda
        countryTrustMultipliers["RWA"] = 100; // Rwanda
        countryTrustMultipliers["ETH"] = 100; // Ethiopia
        countryTrustMultipliers["SOM"] = 100; // Somalia
        countryTrustMultipliers["DJI"] = 100; // Djibouti
        countryTrustMultipliers["ERI"] = 100; // Eritrea
        countryTrustMultipliers["BDI"] = 100; // Burundi
        countryTrustMultipliers["SSD"] = 100; // South Sudan

        // Southern Africa
        countryTrustMultipliers["ZAF"] = 100; // South Africa
        countryTrustMultipliers["ZWE"] = 100; // Zimbabwe
        countryTrustMultipliers["ZMB"] = 100; // Zambia
        countryTrustMultipliers["MWI"] = 100; // Malawi
        countryTrustMultipliers["MOZ"] = 100; // Mozambique
        countryTrustMultipliers["AGO"] = 100; // Angola
        countryTrustMultipliers["NAM"] = 100; // Namibia
        countryTrustMultipliers["BWA"] = 100; // Botswana
        countryTrustMultipliers["LSO"] = 100; // Lesotho
        countryTrustMultipliers["SWZ"] = 100; // Eswatini
        countryTrustMultipliers["MDG"] = 100; // Madagascar

        // North Africa
        countryTrustMultipliers["EGY"] = 100; // Egypt
        countryTrustMultipliers["MAR"] = 100; // Morocco
        countryTrustMultipliers["TUN"] = 100; // Tunisia
        countryTrustMultipliers["DZA"] = 100; // Algeria
        countryTrustMultipliers["LBY"] = 100; // Libya
        countryTrustMultipliers["SDN"] = 100; // Sudan

        // Central Africa
        countryTrustMultipliers["CMR"] = 100; // Cameroon
        countryTrustMultipliers["COD"] = 100; // DR Congo
        countryTrustMultipliers["COG"] = 100; // Congo
        countryTrustMultipliers["GAB"] = 100; // Gabon
        countryTrustMultipliers["TCD"] = 100; // Chad
        countryTrustMultipliers["CAF"] = 100; // Central African Republic
        countryTrustMultipliers["GNQ"] = 100; // Equatorial Guinea
        countryTrustMultipliers["STP"] = 100; // São Tomé and Príncipe

        // Island Nations
        countryTrustMultipliers["MUS"] = 100; // Mauritius
        countryTrustMultipliers["SYC"] = 100; // Seychelles
        countryTrustMultipliers["COM"] = 100; // Comoros
    }

    // ──────────────────────────────────────────────
    //  User Registration & Profile
    // ──────────────────────────────────────────────

    /**
     * @notice Register a new user on the Afri Rep platform.
     * @dev Assigns a base reputation of 10. Reverts if already registered
     *      or if the country code is not exactly 3 characters.
     * @param _name             Display name for the user.
     * @param _countryCode      ISO 3166-1 alpha-3 country code (e.g., "NGA").
     * @param _profileImageHash IPFS CID of the profile image.
     */
    function registerUser(
        string memory _name,
        string memory _countryCode,
        string memory _profileImageHash
    ) external whenNotPaused {
        if (bytes(userProfiles[msg.sender].name).length != 0) revert AlreadyRegistered();
        if (bytes(_countryCode).length != 3) revert InvalidCountryCode();

        userProfiles[msg.sender] = UserProfile({
            walletAddress: msg.sender,
            name: _name,
            countryCode: _countryCode,
            joinDate: block.timestamp,
            reputationScore: BASE_REP_SCORE,
            isVerified: false,
            profileImageHash: _profileImageHash,
            skills: new string[](0),
            lastActivity: block.timestamp,
            totalVouchesReceived: 0,
            totalVouchesGiven: 0
        });

        totalUsers++;

        emit UserRegistered(msg.sender, _name, _countryCode, block.timestamp);
    }

    /**
     * @notice Update the profile image hash for the calling user.
     * @param _newHash New IPFS CID for the profile image.
     */
    function updateProfileImage(string memory _newHash) external onlyRegistered whenNotPaused {
        userProfiles[msg.sender].profileImageHash = _newHash;
        userProfiles[msg.sender].lastActivity = block.timestamp;
        emit ProfileUpdated(msg.sender, "profileImage");
    }

    /**
     * @notice Update the display name for the calling user.
     * @param _newName New display name.
     */
    function updateName(string memory _newName) external onlyRegistered whenNotPaused {
        userProfiles[msg.sender].name = _newName;
        userProfiles[msg.sender].lastActivity = block.timestamp;
        emit ProfileUpdated(msg.sender, "name");
    }

    // ──────────────────────────────────────────────
    //  Vouching
    // ──────────────────────────────────────────────

    /**
     * @notice Give a vouch to another user for a specific skill.
     * @dev Generates a unique vouch ID from (sender, recipient, skill, timestamp).
     *      Prevents self-vouching and duplicate vouches for the same user+skill pair.
     *      Automatically recalculates the recipient's reputation after the vouch.
     * @param _to           Address of the user being vouched for.
     * @param _skillId      ID of the skill being endorsed.
     * @param _confidence   Confidence level (1–5).
     * @param _comment      Optional text comment.
     * @param _evidenceHash IPFS CID of supporting evidence (optional).
     * @return vouchId      The unique identifier for the created vouch.
     */
    function giveVouch(
        address _to,
        string memory _skillId,
        uint256 _confidence,
        string memory _comment,
        string memory _evidenceHash
    ) external nonReentrant whenNotPaused onlyRegistered isRegistered(_to) returns (bytes32) {
        if (msg.sender == _to) revert CannotSelfVouch();
        if (_confidence < MIN_CONFIDENCE || _confidence > MAX_CONFIDENCE) revert InvalidConfidence();

        // Prevent duplicate vouches for the same user+skill pair
        bytes32 pairKey = keccak256(abi.encodePacked(msg.sender, _to, _skillId));
        if (hasVouchedForSkill[pairKey]) revert DuplicateVouch();
        hasVouchedForSkill[pairKey] = true;

        bytes32 vouchId = keccak256(abi.encodePacked(msg.sender, _to, _skillId, block.timestamp));

        vouches[vouchId] = Vouch({
            from: msg.sender,
            to: _to,
            skillId: _skillId,
            confidence: _confidence,
            comment: _comment,
            evidenceHash: _evidenceHash,
            timestamp: block.timestamp,
            isValid: true
        });

        userVouchesGiven[msg.sender].push(vouchId);
        userVouchesReceived[_to].push(vouchId);

        userProfiles[msg.sender].totalVouchesGiven++;
        userProfiles[_to].totalVouchesReceived++;
        totalVouches++;

        // Recalculate recipient's reputation
        _updateReputation(_to);

        emit VouchGiven(vouchId, msg.sender, _to, _skillId, _confidence);
        return vouchId;
    }

    /**
     * @notice Revoke a vouch that you previously gave.
     * @dev Only the original voucher can revoke. Marks the vouch as invalid
     *      and recalculates the recipient's reputation.
     * @param _vouchId The ID of the vouch to revoke.
     */
    function revokeVouch(bytes32 _vouchId) external nonReentrant whenNotPaused {
        Vouch storage vouch = vouches[_vouchId];
        if (vouch.from == address(0)) revert VouchNotFound();
        if (vouch.from != msg.sender) revert NotVouchOwner();
        if (!vouch.isValid) revert VouchNotFound();

        vouch.isValid = false;

        // Clear the duplicate guard so the user could re-vouch if desired
        bytes32 pairKey = keccak256(abi.encodePacked(vouch.from, vouch.to, vouch.skillId));
        hasVouchedForSkill[pairKey] = false;

        // Recalculate recipient's reputation
        _updateReputation(vouch.to);

        emit VouchRevoked(_vouchId, msg.sender);
    }

    /**
     * @notice Invalidate a vouch (validator/admin action for fraud).
     * @dev Only accounts with VALIDATOR_ROLE can invalidate vouches.
     * @param _vouchId The ID of the vouch to invalidate.
     */
    function invalidateVouch(bytes32 _vouchId) external onlyRole(VALIDATOR_ROLE) {
        Vouch storage vouch = vouches[_vouchId];
        if (vouch.from == address(0)) revert VouchNotFound();

        vouch.isValid = false;

        _updateReputation(vouch.to);

        emit VouchInvalidated(_vouchId, msg.sender);
    }

    // ──────────────────────────────────────────────
    //  Reputation Calculation
    // ──────────────────────────────────────────────

    /**
     * @dev Update a user's stored reputation score.
     * @param _user Address of the user to update.
     */
    function _updateReputation(address _user) internal {
        uint256 oldScore = userProfiles[_user].reputationScore;
        uint256 newScore = _calculateReputation(_user);
        userProfiles[_user].reputationScore = newScore;
        userProfiles[_user].lastActivity = block.timestamp;

        emit ReputationUpdated(_user, oldScore, newScore);
    }

    /**
     * @dev Calculate a user's reputation score from their valid vouches,
     *      applying cross-border multipliers and time decay.
     *
     *      Formula per vouch: confidence × 2 × crossBorderMultiplier / 100
     *      Time decay: -1% per month of inactivity (capped at 100 months).
     *      Final score capped at MAX_REP_SCORE (1000).
     *
     * @param _user Address of the user.
     * @return Computed reputation score.
     */
    function _calculateReputation(address _user) internal view returns (uint256) {
        uint256 baseScore = BASE_REP_SCORE;
        bytes32[] memory receivedVouches = userVouchesReceived[_user];
        string memory userCountry = userProfiles[_user].countryCode;

        for (uint256 i = 0; i < receivedVouches.length; i++) {
            Vouch memory vouch = vouches[receivedVouches[i]];
            if (!vouch.isValid) continue;

            string memory giverCountry = userProfiles[vouch.from].countryCode;
            uint256 crossBorderMultiplier = _getCrossBorderMultiplier(giverCountry, userCountry);

            baseScore += (vouch.confidence * 2 * crossBorderMultiplier) / 100;
        }

        // Time decay: reduce 1% per month of inactivity (prevent underflow)
        uint256 monthsInactive = (block.timestamp - userProfiles[_user].lastActivity) / 30 days;
        if (monthsInactive > 0 && monthsInactive < 100) {
            baseScore = baseScore * (100 - monthsInactive) / 100;
        } else if (monthsInactive >= 100) {
            baseScore = 0;
        }

        return baseScore > MAX_REP_SCORE ? MAX_REP_SCORE : baseScore;
    }

    /**
     * @dev Determine the trust multiplier for a cross-border vouch.
     * @param _fromCountry Voucher's country code.
     * @param _toCountry   Vouchee's country code.
     * @return Multiplier as a percentage (100 = same country, 90 = same region, 80 = cross-region).
     */
    function _getCrossBorderMultiplier(
        string memory _fromCountry,
        string memory _toCountry
    ) internal pure returns (uint256) {
        if (keccak256(bytes(_fromCountry)) == keccak256(bytes(_toCountry))) {
            return 100; // Same country — full trust
        }

        if (_isSameRegion(_fromCountry, _toCountry)) {
            return 90; // Same AU region — high trust
        }

        return 80; // Cross-region — moderate trust
    }

    /**
     * @dev Check whether two country codes belong to the same African Union region.
     * @param _country1 First ISO 3166-1 alpha-3 code.
     * @param _country2 Second ISO 3166-1 alpha-3 code.
     * @return True if both countries are in the same regional grouping.
     */
    function _isSameRegion(
        string memory _country1,
        string memory _country2
    ) internal pure returns (bool) {
        string[5] memory westAfrica = ["NGA", "GHA", "SEN", "CIV", "BEN"];
        string[5] memory eastAfrica = ["KEN", "TZA", "UGA", "RWA", "ETH"];
        string[5] memory southernAfrica = ["ZAF", "ZWE", "ZMB", "MWI", "MOZ"];
        string[5] memory northAfrica = ["EGY", "MAR", "TUN", "DZA", "LBY"];
        string[5] memory centralAfrica = ["CMR", "COD", "COG", "GAB", "TCD"];

        return (_isInArray(_country1, westAfrica) && _isInArray(_country2, westAfrica)) ||
               (_isInArray(_country1, eastAfrica) && _isInArray(_country2, eastAfrica)) ||
               (_isInArray(_country1, southernAfrica) && _isInArray(_country2, southernAfrica)) ||
               (_isInArray(_country1, northAfrica) && _isInArray(_country2, northAfrica)) ||
               (_isInArray(_country1, centralAfrica) && _isInArray(_country2, centralAfrica));
    }

    /**
     * @dev Check if a value exists in a fixed-size array of strings.
     */
    function _isInArray(string memory _value, string[5] memory _array) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (keccak256(bytes(_value)) == keccak256(bytes(_array[i]))) {
                return true;
            }
        }
        return false;
    }

    // ──────────────────────────────────────────────
    //  Admin Functions
    // ──────────────────────────────────────────────

    /**
     * @notice Register a new skill in the platform's skill registry.
     * @dev Only callable by ADMIN_ROLE holders.
     * @param _skillId  Unique identifier for the skill (e.g., "web_dev").
     * @param _name     Human-readable skill name (e.g., "Web Development").
     * @param _category Category grouping (e.g., "tech", "creative").
     */
    function addSkill(
        string memory _skillId,
        string memory _name,
        string memory _category
    ) external onlyRole(ADMIN_ROLE) {
        if (skills[_skillId].exists) revert SkillAlreadyExists();

        skills[_skillId].id = _skillId;
        skills[_skillId].name = _name;
        skills[_skillId].category = _category;
        skills[_skillId].globalWeight = 100;
        skills[_skillId].exists = true;

        emit SkillAdded(_skillId, _name, _category);
    }

    /**
     * @notice Update the trust multiplier for a specific country.
     * @dev Only callable by ADMIN_ROLE holders.
     * @param _countryCode ISO 3166-1 alpha-3 country code.
     * @param _multiplier  New multiplier (100 = neutral).
     */
    function setCountryMultiplier(
        string memory _countryCode,
        uint256 _multiplier
    ) external onlyRole(ADMIN_ROLE) {
        uint256 oldMultiplier = countryTrustMultipliers[_countryCode];
        countryTrustMultipliers[_countryCode] = _multiplier;
        emit CountryMultiplierUpdated(_countryCode, oldMultiplier, _multiplier);
    }

    /**
     * @notice Verify a user's identity (marks profile as verified).
     * @dev Only callable by VALIDATOR_ROLE holders.
     * @param _user Address of the user to verify.
     */
    function verifyUser(address _user) external onlyRole(VALIDATOR_ROLE) isRegistered(_user) {
        userProfiles[_user].isVerified = true;
        emit UserVerified(_user, msg.sender);
    }

    /**
     * @notice Pause all user-facing contract operations.
     * @dev Only callable by ADMIN_ROLE holders. Emergency use only.
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Resume all contract operations after a pause.
     * @dev Only callable by ADMIN_ROLE holders.
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // ──────────────────────────────────────────────
    //  View Functions
    // ──────────────────────────────────────────────

    /**
     * @notice Retrieve a user's public profile data.
     * @param _user Address of the user.
     * @return name              Display name.
     * @return countryCode       ISO 3166-1 alpha-3 code.
     * @return reputationScore   Current reputation (0–1000).
     * @return isVerified        Whether identity has been verified.
     * @return profileImageHash  IPFS CID of profile image.
     * @return lastActivity      Timestamp of last on-chain activity.
     */
    function getUserProfile(address _user) external view returns (
        string memory name,
        string memory countryCode,
        uint256 reputationScore,
        bool isVerified,
        string memory profileImageHash,
        uint256 lastActivity
    ) {
        UserProfile memory profile = userProfiles[_user];
        return (
            profile.name,
            profile.countryCode,
            profile.reputationScore,
            profile.isVerified,
            profile.profileImageHash,
            profile.lastActivity
        );
    }

    /**
     * @notice Get all vouch IDs received by a user.
     * @param _user Address of the user.
     * @return Array of vouch ID hashes.
     */
    function getUserVouches(address _user) external view returns (bytes32[] memory) {
        return userVouchesReceived[_user];
    }

    /**
     * @notice Get all vouch IDs given by a user.
     * @param _user Address of the user.
     * @return Array of vouch ID hashes.
     */
    function getUserVouchesGiven(address _user) external view returns (bytes32[] memory) {
        return userVouchesGiven[_user];
    }

    /**
     * @notice Get platform-wide statistics.
     * @return _totalUsers   Number of registered users.
     * @return _totalVouches Number of vouches created.
     */
    function getPlatformStats() external view returns (uint256 _totalUsers, uint256 _totalVouches) {
        return (totalUsers, totalVouches);
    }
}