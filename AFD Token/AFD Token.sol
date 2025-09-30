// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AFDToken is ERC20, Ownable {
    address public liquidityPool;
    bool public liquidityLocked = false;

    uint256 private constant TOTAL_SUPPLY = 1000000 * 10**18;
    uint256 private constant LIQUIDITY_SUPPLY = TOTAL_SUPPLY / 2;

    event LiquidityPoolSet(address indexed pool);
    event LiquidityTransferred(address indexed pool, uint256 amount);

    constructor()
        ERC20("AFD Token", "AFD")
        Ownable(msg.sender)
    {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function setLiquidityPool(address _liquidityPool) external onlyOwner {
        require(_liquidityPool != address(0), "Invalid liquidity pool address");
        require(!liquidityLocked, "Liquidity already set and locked");
        require(liquidityPool == address(0), "Liquidity pool already set");
        
        liquidityPool = _liquidityPool;
        liquidityLocked = true;
        
        _transfer(msg.sender, _liquidityPool, LIQUIDITY_SUPPLY);
        
        emit LiquidityPoolSet(_liquidityPool);
        emit LiquidityTransferred(_liquidityPool, LIQUIDITY_SUPPLY);
    }

    function getLiquiditySupply() external pure returns (uint256) {
        return LIQUIDITY_SUPPLY;
    }

    
    function getTotalSupply() external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function _beforeTokenTransfer(
        address from,
        address _to,
        uint256 _amount
    ) internal virtual {
        
        
        if (from == address(0)) {
            return;
        }
    
        if (from == owner() && !liquidityLocked) {
            return;
        }
        
        require(liquidityLocked, "Liquidity not yet allocated");
    }
}