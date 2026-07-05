// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title AfriStablecoin (AFD) — Pan-African Stablecoin
 * @author Afri Rep Contributors
 * @notice A stablecoin pegged 1:1 to USD, designed for cross-border
 *         transactions across African markets. Supports minting via
 *         multiple African fiat currencies at configurable exchange rates.
 * @dev Fiat-to-AFD rates are maintained on-chain (simplified oracle model).
 *      In production, a decentralized oracle (Chainlink, Band, etc.)
 *      should replace the admin-set rates. Includes pause capability for
 *      emergency scenarios and per-transaction mint limits.
 */
contract AfriStablecoin is ERC20, AccessControl, Pausable {
    // ──────────────────────────────────────────────
    //  Roles
    // ──────────────────────────────────────────────

    /// @notice Role permitted to mint new AFD tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role permitted to burn AFD tokens.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Role permitted to update exchange rates.
    bytes32 public constant RATE_UPDATER_ROLE = keccak256("RATE_UPDATER_ROLE");

    // ──────────────────────────────────────────────
    //  State
    // ──────────────────────────────────────────────

    /// @notice Whether a fiat currency code is supported for minting.
    mapping(string => bool) public supportedFiatCurrencies;

    /// @notice Fiat currency code → units of fiat per 1 AFD (e.g., NGN → 800).
    mapping(string => uint256) public fiatToAFDRate;

    /// @notice Maximum AFD that can be minted in a single transaction.
    uint256 public maxMintPerTx;

    /// @notice Total AFD ever minted (gross, before burns).
    uint256 public totalMinted;

    /// @notice Total AFD ever burned.
    uint256 public totalBurned;

    /// @notice List of all supported currency codes (for enumeration).
    string[] public supportedCurrencyList;

    // ──────────────────────────────────────────────
    //  Events
    // ──────────────────────────────────────────────

    /// @notice Emitted when AFD is minted via a fiat deposit.
    event Minted(address indexed to, uint256 afdAmount, string currency, uint256 fiatAmount, uint256 rate);

    /// @notice Emitted when AFD is burned (redeemed for fiat).
    event Burned(address indexed from, uint256 amount);

    /// @notice Emitted when a new fiat currency is added.
    event FiatCurrencyAdded(string currency, uint256 rate);

    /// @notice Emitted when a fiat exchange rate is updated.
    event RateUpdated(string currency, uint256 oldRate, uint256 newRate);

    /// @notice Emitted when the per-transaction mint limit changes.
    event MaxMintUpdated(uint256 oldLimit, uint256 newLimit);

    // ──────────────────────────────────────────────
    //  Errors
    // ──────────────────────────────────────────────

    /// @notice Thrown when the specified currency is not supported.
    error CurrencyNotSupported();

    /// @notice Thrown when the fiat amount is zero or negative.
    error AmountMustBePositive();

    /// @notice Thrown when a mint exceeds the per-transaction limit.
    error ExceedsMaxMint();

    /// @notice Thrown when trying to add a currency that already exists.
    error CurrencyAlreadyExists();

    /// @notice Thrown when the exchange rate is zero.
    error InvalidRate();

    // ──────────────────────────────────────────────
    //  Constructor
    // ──────────────────────────────────────────────

    /**
     * @notice Deploy the AfriDollar stablecoin with initial currency support.
     * @dev Sets up roles and initializes exchange rates for the 5 largest
     *      African economies. Default max mint is 1,000,000 AFD per tx.
     */
    constructor() ERC20("AfriDollar", "AFD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(RATE_UPDATER_ROLE, msg.sender);

        maxMintPerTx = 1_000_000 * 1e18; // 1M AFD per transaction

        // Phase 1 currencies — major African economies
        _addFiatCurrency("NGN", 800);   // Nigerian Naira
        _addFiatCurrency("KES", 150);   // Kenyan Shilling
        _addFiatCurrency("ZAR", 18);    // South African Rand
        _addFiatCurrency("GHS", 12);    // Ghanaian Cedi
        _addFiatCurrency("EGP", 30);    // Egyptian Pound

        // Phase 2 currencies — regional expansion
        _addFiatCurrency("XOF", 600);   // West African CFA Franc
        _addFiatCurrency("XAF", 600);   // Central African CFA Franc
        _addFiatCurrency("TZS", 2500);  // Tanzanian Shilling
        _addFiatCurrency("UGX", 3700);  // Ugandan Shilling
        _addFiatCurrency("ETB", 56);    // Ethiopian Birr
        _addFiatCurrency("MAD", 10);    // Moroccan Dirham
        _addFiatCurrency("RWF", 1200);  // Rwandan Franc
        _addFiatCurrency("AOA", 830);   // Angolan Kwanza
        _addFiatCurrency("MUR", 45);    // Mauritian Rupee
    }

    // ──────────────────────────────────────────────
    //  Minting
    // ──────────────────────────────────────────────

    /**
     * @notice Mint AFD tokens for a user who has deposited fiat currency.
     * @dev Only callable by MINTER_ROLE. Converts fiat amount to AFD using
     *      the stored exchange rate. Respects the per-transaction limit.
     * @param _to         Recipient of the minted AFD.
     * @param _fiatAmount Amount of fiat currency deposited (in smallest unit).
     * @param _currency   ISO 4217 currency code (e.g., "NGN").
     */
    function mintWithFiat(
        address _to,
        uint256 _fiatAmount,
        string memory _currency
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        if (!supportedFiatCurrencies[_currency]) revert CurrencyNotSupported();
        if (_fiatAmount == 0) revert AmountMustBePositive();

        uint256 afdAmount = _fiatAmount * 1e18 / fiatToAFDRate[_currency];
        if (afdAmount > maxMintPerTx) revert ExceedsMaxMint();

        _mint(_to, afdAmount);
        totalMinted += afdAmount;

        emit Minted(_to, afdAmount, _currency, _fiatAmount, fiatToAFDRate[_currency]);
    }

    // ──────────────────────────────────────────────
    //  Burning (Fiat Redemption)
    // ──────────────────────────────────────────────

    /**
     * @notice Burn AFD tokens when a user redeems for fiat.
     * @dev Only callable by BURNER_ROLE.
     * @param _from   Address whose tokens are burned.
     * @param _amount Amount of AFD to burn (18 decimals).
     */
    function burn(address _from, uint256 _amount) external onlyRole(BURNER_ROLE) whenNotPaused {
        if (_amount == 0) revert AmountMustBePositive();
        _burn(_from, _amount);
        totalBurned += _amount;
        emit Burned(_from, _amount);
    }

    // ──────────────────────────────────────────────
    //  Currency Management
    // ──────────────────────────────────────────────

    /**
     * @dev Internal helper to register a new fiat currency.
     * @param _currency ISO 4217 code.
     * @param _rate     Units of fiat per 1 AFD.
     */
    function _addFiatCurrency(string memory _currency, uint256 _rate) internal {
        supportedFiatCurrencies[_currency] = true;
        fiatToAFDRate[_currency] = _rate;
        supportedCurrencyList.push(_currency);
        emit FiatCurrencyAdded(_currency, _rate);
    }

    /**
     * @notice Add a new supported fiat currency with its exchange rate.
     * @dev Only callable by DEFAULT_ADMIN_ROLE.
     * @param _currency ISO 4217 code (e.g., "TZS").
     * @param _rate     Units of fiat per 1 AFD.
     */
    function addFiatCurrency(
        string memory _currency,
        uint256 _rate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (supportedFiatCurrencies[_currency]) revert CurrencyAlreadyExists();
        if (_rate == 0) revert InvalidRate();
        _addFiatCurrency(_currency, _rate);
    }

    /**
     * @notice Update the exchange rate for an existing supported currency.
     * @dev Only callable by RATE_UPDATER_ROLE.
     * @param _currency ISO 4217 code.
     * @param _newRate  New units of fiat per 1 AFD.
     */
    function updateRate(
        string memory _currency,
        uint256 _newRate
    ) external onlyRole(RATE_UPDATER_ROLE) {
        if (!supportedFiatCurrencies[_currency]) revert CurrencyNotSupported();
        if (_newRate == 0) revert InvalidRate();

        uint256 oldRate = fiatToAFDRate[_currency];
        fiatToAFDRate[_currency] = _newRate;
        emit RateUpdated(_currency, oldRate, _newRate);
    }

    /**
     * @notice Update the per-transaction mint limit.
     * @dev Only callable by DEFAULT_ADMIN_ROLE.
     * @param _newMax New maximum AFD per transaction (18 decimals).
     */
    function setMaxMintPerTx(uint256 _newMax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldLimit = maxMintPerTx;
        maxMintPerTx = _newMax;
        emit MaxMintUpdated(oldLimit, _newMax);
    }

    // ──────────────────────────────────────────────
    //  Pause / Unpause
    // ──────────────────────────────────────────────

    /// @notice Pause all minting and burning (emergency only).
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Resume normal operations after a pause.
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // ──────────────────────────────────────────────
    //  View Functions
    // ──────────────────────────────────────────────

    /**
     * @notice Get the total number of supported fiat currencies.
     * @return Count of supported currencies.
     */
    function getSupportedCurrencyCount() external view returns (uint256) {
        return supportedCurrencyList.length;
    }

    /**
     * @notice Get the net supply (minted minus burned).
     * @return Net AFD in circulation.
     */
    function getNetSupply() external view returns (uint256) {
        return totalMinted - totalBurned;
    }
}