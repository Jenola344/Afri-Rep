// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IAfriRep.sol";


/**
 * @title AfriRep Core Contract
 * @dev Main contract for Afri Rep reputation system
 * Features: User profiles, skill management, cross-border reputation
 */
contract AfriRep is Initializable, AccessControlUpgradeable, IAfriRep {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    
    // User profile structure
    struct UserProfile {
        address walletAddress;
        string name;
        string countryCode; // ISO 3166-1 alpha-3
        uint256 joinDate;
        uint256 reputationScore;
        bool isVerified;
        string profileImageHash;
        string[] skills;
        uint256 lastActivity;
    }
    
    // Skill structure
    struct Skill {
        string id;
        string name;
        string category;
        uint256 globalWeight;
        mapping(string => uint256) regionalWeights; // countryCode => weight
    }
    
    // Vouch structure
    struct Vouch {
        address from;
        address to;
        string skillId;
        uint256 confidence; // 1-5
        string comment;
        string evidenceHash; // IPFS hash
        uint256 timestamp;
        bool isValid;
    }
    
    // Mapping from user address to profile
    mapping(address => UserProfile) public userProfiles;
    
    // Mapping from skill ID to Skill
    mapping(string => Skill) public skills;
    
    // Mapping from vouch ID to Vouch
    mapping(bytes32 => Vouch) public vouches;
    
    // User's vouches given and received
    mapping(address => bytes32[]) public userVouchesGiven;
    mapping(address => bytes32[]) public userVouchesReceived;
    
    // Country trust multipliers
    mapping(string => uint256) public countryTrustMultipliers; // countryCode => multiplier (percentage)
    
    // Events
    event UserRegistered(address indexed user, string name, string countryCode);
    event VouchGiven(bytes32 indexed vouchId, address from, address to, string skillId);
    event VouchInvalidated(bytes32 indexed vouchId, address invalidator);
    event ReputationUpdated(address indexed user, uint256 newScore);
    event SkillAdded(string skillId, string name, string category);
    event CountryMultiplierUpdated(string countryCode, uint256 multiplier);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize() initializer public {
        __AccessControl_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(VALIDATOR_ROLE, msg.sender);
        
        // Initialize with African country multipliers
        _initializeCountryMultipliers();
    }
    
    function _initializeCountryMultipliers() internal {
        // Set base multipliers for African countries (can be updated by admin)
        countryTrustMultipliers["NGA"] = 100; // Nigeria
        countryTrustMultipliers["KEN"] = 100; // Kenya
        countryTrustMultipliers["ZAF"] = 100; // South Africa
        countryTrustMultipliers["GHA"] = 100; // Ghana
        countryTrustMultipliers["EGY"] = 100; // Egypt
        // Add more African countries...
    }
    
    /**
     * @dev Register a new user
     */
    function registerUser(
        string memory _name,
        string memory _countryCode,
        string memory _profileImageHash
    ) external {
        require(bytes(userProfiles[msg.sender].name).length == 0, "User already registered");
        require(bytes(_countryCode).length == 3, "Invalid country code");
        
        userProfiles[msg.sender] = UserProfile({
            walletAddress: msg.sender,
            name: _name,
            countryCode: _countryCode,
            joinDate: block.timestamp,
            reputationScore: 10, // Base score
            isVerified: false,
            profileImageHash: _profileImageHash,
            skills: new string[](0),
            lastActivity: block.timestamp
        });
        
        emit UserRegistered(msg.sender, _name, _countryCode);
    }
    
    /**
     * @dev Give a vouch to another user
     */
    function giveVouch(
        address _to,
        string memory _skillId,
        uint256 _confidence,
        string memory _comment,
        string memory _evidenceHash
    ) external returns (bytes32) {
        require(msg.sender != _to, "Cannot vouch for yourself");
        require(bytes(userProfiles[msg.sender].name).length > 0, "Sender not registered");
        require(bytes(userProfiles[_to].name).length > 0, "Recipient not registered");
        require(_confidence >= 1 && _confidence <= 5, "Confidence must be 1-5");
        
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
        
        // Update reputation scores
        _updateReputation(_to);
        
        emit VouchGiven(vouchId, msg.sender, _to, _skillId);
        return vouchId;
    }
    
    /**
     * @dev Update user reputation based on vouches
     */
    function _updateReputation(address _user) internal {
        uint256 newScore = _calculateReputation(_user);
        userProfiles[_user].reputationScore = newScore;
        userProfiles[_user].lastActivity = block.timestamp;
        
        emit ReputationUpdated(_user, newScore);
    }
    
    /**
     * @dev Calculate reputation score with cross-border adjustments
     */
    function _calculateReputation(address _user) internal view returns (uint256) {
        uint256 baseScore = 10; // Starting score
        bytes32[] memory userVouches = userVouchesReceived[_user];
        string memory userCountry = userProfiles[_user].countryCode;
        
        for (uint256 i = 0; i < userVouches.length; i++) {
            Vouch memory vouch = vouches[userVouches[i]];
            if (!vouch.isValid) continue;
            
            // Get vouch giver's country
            string memory giverCountry = userProfiles[vouch.from].countryCode;
            
            // Calculate cross-border multiplier
            uint256 crossBorderMultiplier = _getCrossBorderMultiplier(giverCountry, userCountry);
            
            // Add weighted vouch score
            baseScore += (vouch.confidence * 2 * crossBorderMultiplier) / 100;
        }
        
        // Time decay: reduce 1% per month of inactivity
        uint256 monthsInactive = (block.timestamp - userProfiles[_user].lastActivity) / 30 days;
        if (monthsInactive > 0) {
            baseScore = baseScore * (100 - monthsInactive) / 100;
        }
        
        return baseScore > 1000 ? 1000 : baseScore; // Cap at 1000
    }
    
    /**
     * @dev Get cross-border trust multiplier
     */
    function _getCrossBorderMultiplier(
    string memory _fromCountry,
    string memory _toCountry
) internal pure returns (uint256) {
        if (keccak256(bytes(_fromCountry)) == keccak256(bytes(_toCountry))) {
            return 100; // Same country
        }
        
        // Regional trust bridges (West Africa, East Africa, etc.)
        if (_isSameRegion(_fromCountry, _toCountry)) {
            return 90; // Same region
        }
        
        return 80; // Different regions
    }
    
    /**
     * @dev Check if two countries are in the same African region
     */
    function _isSameRegion(
        string memory _country1, 
        string memory _country2
    ) internal pure returns (bool) {
        // Simplified regional grouping - expand based on AU regions
        string[5] memory westAfrica = ["NGA", "GHA", "SEN", "CIV", "BEN"];
        string[5] memory eastAfrica = ["KEN", "TZA", "UGA", "RWA", "ETH"];
        string[5] memory southernAfrica = ["ZAF", "ZWE", "ZMB", "MWI", "MOZ"];
        string[5] memory northAfrica = ["EGY", "MAR", "TUN", "DZA", "LBY"];
        
        return _isInArray(_country1, westAfrica) && _isInArray(_country2, westAfrica) ||
               _isInArray(_country1, eastAfrica) && _isInArray(_country2, eastAfrica) ||
               _isInArray(_country1, southernAfrica) && _isInArray(_country2, southernAfrica) ||
               _isInArray(_country1, northAfrica) && _isInArray(_country2, northAfrica);
    }
    
    function _isInArray(string memory _value, string[5] memory _array) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (keccak256(bytes(_value)) == keccak256(bytes(_array[i]))) {
                return true;
            }
        }
        return false;
    }
    
    // Admin functions
    function addSkill(
        string memory _skillId, 
        string memory _name, 
        string memory _category
    ) external onlyRole(ADMIN_ROLE) {
        skills[_skillId].id = _skillId;
        skills[_skillId].name = _name;
        skills[_skillId].category = _category;
        skills[_skillId].globalWeight = 100;
        
        emit SkillAdded(_skillId, _name, _category);
    }
    
    function setCountryMultiplier(
        string memory _countryCode, 
        uint256 _multiplier
    ) external onlyRole(ADMIN_ROLE) {
        countryTrustMultipliers[_countryCode] = _multiplier;
        emit CountryMultiplierUpdated(_countryCode, _multiplier);
    }
    
    // View functions
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
    
    function getUserVouches(address _user) external view returns (bytes32[] memory) {
        return userVouchesReceived[_user];
    }
}