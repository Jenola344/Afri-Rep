// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AfriDollar (AFD) - Pan-African Stablecoin
 * @dev Pegged 1:1 with USD, designed for African markets
 */
contract AfriStablecoin is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    // Supported African fiat currencies for minting
    mapping(string => bool) public supportedFiatCurrencies;
    
    // Exchange rates (simplified - would use oracle in production)
    mapping(string => uint256) public fiatToAFDRate; // currency => rate per 1 AFD
    
    event Minted(address indexed to, uint256 amount, string currency, uint256 rate);
    event Burned(address indexed from, uint256 amount);
    event FiatCurrencyAdded(string currency, uint256 rate);
    
    constructor() ERC20("AfriDollar", "AFD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        
        // Initialize with major African currencies
        _addFiatCurrency("NGN", 800); // 1 AFD = 800 Naira
        _addFiatCurrency("KES", 150); // 1 AFD = 150 Kenyan Shillings
        _addFiatCurrency("ZAR", 18);  // 1 AFD = 18 Rand
        _addFiatCurrency("GHS", 12);  // 1 AFD = 12 Cedis
        _addFiatCurrency("EGP", 30);  // 1 AFD = 30 Egyptian Pounds
    }
    
    function mintWithFiat(
        address _to,
        uint256 _fiatAmount,
        string memory _currency
    ) external onlyRole(MINTER_ROLE) {
        require(supportedFiatCurrencies[_currency], "Currency not supported");
        require(_fiatAmount > 0, "Amount must be positive");
        
        uint256 afdAmount = _fiatAmount * 1e18 / fiatToAFDRate[_currency];
        _mint(_to, afdAmount);
        
        emit Minted(_to, afdAmount, _currency, fiatToAFDRate[_currency]);
    }
    
    function burn(address _from, uint256 _amount) external onlyRole(BURNER_ROLE) {
        _burn(_from, _amount);
        emit Burned(_from, _amount);
    }
    
    function _addFiatCurrency(string memory _currency, uint256 _rate) internal {
        supportedFiatCurrencies[_currency] = true;
        fiatToAFDRate[_currency] = _rate;
        emit FiatCurrencyAdded(_currency, _rate);
    }
    
    function addFiatCurrency(
        string memory _currency, 
        uint256 _rate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addFiatCurrency(_currency, _rate);
    }
}