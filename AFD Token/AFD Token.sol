// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AFDToken — Afri Rep Governance & Utility Token
 * @author Afri Rep Contributors
 * @notice ERC-20 governance token for the Afri Rep ecosystem. Total supply
 *         of 1,000,000 AFD with 50% allocated to a liquidity pool. Includes
 *         deflationary burn mechanics and whale protection via per-transaction
 *         transfer limits.
 * @dev Transfers are gated: no transfers (except minting) can occur until
 *      the owner sets a liquidity pool address, which locks permanently.
 */
contract AFDToken is ERC20, Ownable {
    // ──────────────────────────────────────────────
    //  Constants
    // ──────────────────────────────────────────────

    /// @notice Total token supply (1,000,000 AFD with 18 decimals).
    uint256 private constant TOTAL_SUPPLY = 1_000_000 * 10**18;

    /// @notice Liquidity allocation (50% of total supply).
    uint256 private constant LIQUIDITY_SUPPLY = TOTAL_SUPPLY / 2;

    /// @notice Maximum tokens transferable in a single transaction (1% of supply).
    /// @dev Whale protection — prevents large dumps that destabilize price.
    uint256 public constant MAX_TRANSFER_AMOUNT = TOTAL_SUPPLY / 100;

    // ──────────────────────────────────────────────
    //  State
    // ──────────────────────────────────────────────

    /// @notice Address of the liquidity pool (set once, immutable after).
    address public liquidityPool;

    /// @notice Whether the liquidity pool has been set and locked.
    bool public liquidityLocked = false;

    /// @notice Total tokens burned (deflationary tracking).
    uint256 public totalBurned;

    /// @notice Addresses exempt from the max transfer limit.
    mapping(address => bool) public isExemptFromLimit;

    // ──────────────────────────────────────────────
    //  Events
    // ──────────────────────────────────────────────

    /// @notice Emitted when the liquidity pool is set and locked.
    event LiquidityPoolSet(address indexed pool);

    /// @notice Emitted when liquidity tokens are transferred to the pool.
    event LiquidityTransferred(address indexed pool, uint256 amount);

    /// @notice Emitted when tokens are burned.
    event TokensBurned(address indexed burner, uint256 amount);

    /// @notice Emitted when an address is exempted from (or re-subjected to) transfer limits.
    event TransferLimitExemption(address indexed account, bool exempt);

    // ──────────────────────────────────────────────
    //  Errors
    // ──────────────────────────────────────────────

    /// @notice Thrown when the liquidity pool address is zero.
    error InvalidPoolAddress();

    /// @notice Thrown when the liquidity pool is already set.
    error LiquidityAlreadyLocked();

    /// @notice Thrown when trying to transfer before liquidity is allocated.
    error LiquidityNotAllocated();

    /// @notice Thrown when a transfer exceeds the per-transaction limit.
    error ExceedsMaxTransfer();

    /// @notice Thrown when trying to burn zero tokens.
    error BurnAmountZero();

    // ──────────────────────────────────────────────
    //  Constructor
    // ──────────────────────────────────────────────

    /**
     * @notice Deploy the AFD token, minting the entire supply to the deployer.
     * @dev The deployer receives TOTAL_SUPPLY and is the initial owner.
     *      They must call `setLiquidityPool` before tokens can be freely traded.
     */
    constructor()
        ERC20("AFD Token", "AFD")
        Ownable(msg.sender)
    {
        _mint(msg.sender, TOTAL_SUPPLY);
        isExemptFromLimit[msg.sender] = true;
    }

    // ──────────────────────────────────────────────
    //  Liquidity Management
    // ──────────────────────────────────────────────

    /**
     * @notice Set the liquidity pool address and transfer 50% of supply to it.
     * @dev Can only be called once. After this call, `liquidityLocked` is true
     *      and normal transfers are enabled.
     * @param _liquidityPool Address of the DEX liquidity pool.
     */
    function setLiquidityPool(address _liquidityPool) external onlyOwner {
        if (_liquidityPool == address(0)) revert InvalidPoolAddress();
        if (liquidityLocked) revert LiquidityAlreadyLocked();
        if (liquidityPool != address(0)) revert LiquidityAlreadyLocked();

        liquidityPool = _liquidityPool;
        liquidityLocked = true;
        isExemptFromLimit[_liquidityPool] = true;

        _transfer(msg.sender, _liquidityPool, LIQUIDITY_SUPPLY);

        emit LiquidityPoolSet(_liquidityPool);
        emit LiquidityTransferred(_liquidityPool, LIQUIDITY_SUPPLY);
    }

    // ──────────────────────────────────────────────
    //  Burn (Deflationary)
    // ──────────────────────────────────────────────

    /**
     * @notice Burn tokens from the caller's balance permanently.
     * @dev Reduces total supply. Anyone can burn their own tokens.
     * @param _amount Number of tokens to burn (with 18 decimals).
     */
    function burn(uint256 _amount) external {
        if (_amount == 0) revert BurnAmountZero();
        _burn(msg.sender, _amount);
        totalBurned += _amount;
        emit TokensBurned(msg.sender, _amount);
    }

    // ──────────────────────────────────────────────
    //  Admin
    // ──────────────────────────────────────────────

    /**
     * @notice Exempt or un-exempt an address from the per-transaction transfer limit.
     * @dev Useful for exchange listings, staking contracts, and treasury.
     * @param _account Address to modify.
     * @param _exempt  True to exempt, false to remove exemption.
     */
    function setTransferLimitExemption(address _account, bool _exempt) external onlyOwner {
        isExemptFromLimit[_account] = _exempt;
        emit TransferLimitExemption(_account, _exempt);
    }

    // ──────────────────────────────────────────────
    //  View Functions
    // ──────────────────────────────────────────────

    /// @notice Returns the initial liquidity allocation amount.
    function getLiquiditySupply() external pure returns (uint256) {
        return LIQUIDITY_SUPPLY;
    }

    /// @notice Returns the total initial supply (before any burns).
    function getTotalSupply() external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    /// @notice Returns the circulating supply (total supply minus burned tokens).
    function getCirculatingSupply() external view returns (uint256) {
        return TOTAL_SUPPLY - totalBurned;
    }

    // ──────────────────────────────────────────────
    //  Transfer Hook
    // ──────────────────────────────────────────────

    /**
     * @dev Hook called before every token transfer. Enforces:
     *      1. No transfers (except minting) until liquidity is locked.
     *      2. Per-transaction transfer limit for non-exempt addresses.
     * @param from   Sender (address(0) for minting).
     * @param _to    Recipient.
     * @param _amount Transfer amount.
     */
    function _beforeTokenTransfer(
        address from,
        address _to,
        uint256 _amount
    ) internal virtual {
        // Allow minting
        if (from == address(0)) return;

        // Allow owner transfers before liquidity lock (for initial setup)
        if (from == owner() && !liquidityLocked) return;

        // After setup: require liquidity to be locked
        if (!liquidityLocked) revert LiquidityNotAllocated();

        // Whale protection: enforce max transfer for non-exempt addresses
        if (!isExemptFromLimit[from] && !isExemptFromLimit[_to]) {
            if (_amount > MAX_TRANSFER_AMOUNT) revert ExceedsMaxTransfer();
        }
    }
}