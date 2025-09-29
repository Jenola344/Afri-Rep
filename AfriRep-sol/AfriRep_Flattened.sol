
// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v5.3.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reinitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Pointer to storage slot. Allows integrators to override it with a custom storage location.
     *
     * NOTE: Consider following the ERC-7201 formula to derive storage locations.
     */
    function _initializableStorageSlot() internal pure virtual returns (bytes32) {
        return INITIALIZABLE_STORAGE;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        bytes32 slot = _initializableStorageSlot();
        assembly {
            $.slot := slot
        }
    }
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts (last updated v5.4.0) (access/IAccessControl.sol)

pragma solidity >=0.8.4;

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted to signal this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call. This account bears the admin role (for the granted role).
     * Expected in cases where the role was granted using the internal {AccessControl-_grantRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol


// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol


// OpenZeppelin Contracts (last updated v5.4.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;






/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControl, ERC165Upgradeable {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;


    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
    struct AccessControlStorage {
        mapping(bytes32 role => RoleData) _roles;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlStorageLocation = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

    function _getAccessControlStorage() private pure returns (AccessControlStorage storage $) {
        assembly {
            $.slot := AccessControlStorageLocation
        }
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        AccessControlStorage storage $ = _getAccessControlStorage();
        bytes32 previousAdminRole = getRoleAdmin(role);
        $._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (!hasRole(role, account)) {
            $._roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` from `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (hasRole(role, account)) {
            $._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// File: contracts/AfriRep/interfaces/IAfriRep.sol


pragma solidity ^0.8.19;

interface IAfriRep {
    // Admin functions
    function addSkill(
        string memory _skillId,
        string memory _name,
        string memory _category
    ) external;

    function setCountryMultiplier(
        string memory _countryCode,
        uint256 _multiplier
    ) external;

    // User functions
    function registerUser(
        string memory _name,
        string memory _countryCode,
        string memory _profileImageHash
    ) external;

    function giveVouch(
        address _to,
        string memory _skillId,
        uint256 _confidence,
        string memory _comment,
        string memory _evidenceHash
    ) external returns (bytes32);

    // View functions
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

    function getUserVouches(address _user)
        external
        view
        returns (bytes32[] memory);
}
// File: contracts/AfriRep/AfriRep.sol


pragma solidity ^0.8.19;





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