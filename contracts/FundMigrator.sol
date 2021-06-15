// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import './lib/SafeMath.sol';
import './interfaces/ISwapV2Router.sol';

/**
 * @title FundMigrator
 * @notice FundMigrator remove old liquity and add new liquity.
 */
contract FundMigrator {
    using SafeMath for uint256;

    address public governance;

    uint256 private desiredRate;
    uint256 constant private desiredDenominator=1000;

    event DesiredRateSet(uint256 _rate);
    event Split(uint256 _amountA, uint256 _amountB, uint256 _liquidity);
    event Compose(uint256 _amountA, uint256 _amountB, uint256 _liquidity);

    constructor() public {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(governance == msg.sender, "Caller is not the governance.");
        _;
    }

    function setDesiredRate(uint256 _rate) external onlyGovernance {
        require(_rate != desiredRate, "This is already the current swap desired rate.");
        require(_rate <= desiredDenominator, "The swap desired rate cannot be greater than 100%.");
        desiredRate = _rate;
        emit DesiredRateSet(_rate);
    }

    // 提取LP代币
    function split(
        address _router, 
        address _tokenA, 
        address _tokenB, 
        uint256 _liquidity,
        uint256 _deadline) internal returns (uint256 amountA, uint256 amountB) {
        require(_router != address(0), "Invalid liquity factory contract.");
        (amountA, amountB) = ISwapV2Router(_router).removeLiquidity(
            _tokenA,
            _tokenB,
            _liquidity,
            0,
            0,
            msg.sender,
            _deadline
        );
        emit Split(amountA, amountB, _liquidity);
    }
    
    // 重组LP代币
    function compose(
        address _router,
        address _tokenA, 
        address _tokenB, 
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _deadline) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(_router != address(0), "Invalid liquity factory contract.");
        uint256 amountADesired = _amountADesired.mul(desiredRate).div(desiredDenominator);
        uint256 amountBDesired = _amountBDesired.mul(desiredRate).div(desiredDenominator);
        (amountA, amountB, liquidity) = ISwapV2Router(_router).addLiquidity(
            _tokenA,
            _tokenB,
            amountADesired,
            amountBDesired,
            0,
            0,
            msg.sender,
            _deadline
        ); 
        emit Compose(amountA, amountB, liquidity);
    }

    // 迁移功能
    function migrate(
        address _oldRouter, 
        address _newRouter, 
        address _tokenA, 
        address _tokenB, 
        uint256 _oldLiquidity,
        uint256 _deadline) external returns (uint256, uint256, uint256) {
        (uint256 amountA, uint256 amountB) = split(
            _oldRouter,
            _tokenA,
            _tokenB,
            _oldLiquidity,
            _deadline
        );

        (uint256 newAmountA, uint256 newAmountB, uint256 newLiquidity) = compose(
            _newRouter,
            _tokenA,
            _tokenB,
            amountA,
            amountB,
            _deadline
        );

        uint256 remainAmountA = newAmountA > amountA ? newAmountA.sub(amountA) : amountA.sub(newAmountA);
        uint256 remainAmountB = newAmountB > amountB ? newAmountB.sub(amountB) : amountB.sub(newAmountB);
        return (remainAmountA, remainAmountB, newLiquidity);
    }
}
