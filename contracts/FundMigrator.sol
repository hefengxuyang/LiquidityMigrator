// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import './interfaces/ISwapV2Factory.sol';
import './interfaces/ISwapV2Pair.sol';
import './interfaces/ISwapV2Router.sol';
import './lib/TransferHelper.sol';


/**
 * @title FundMigrator
 * @notice FundMigrator remove old liquity and add new liquity.
 */
contract FundMigrator {
    using SafeMath for uint256;

    address public governance;
    uint256 private desiredRate;

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

    // 设置容忍的流动性迁移误差比例（即分子占比，分母固定为1000）
    function setDesiredRate(uint256 _rate) external onlyGovernance {
        require(_rate != desiredRate, "This is already the current swap desired rate.");
        require(_rate <= 1e18, "The swap desired rate cannot be greater than 100%.");
        desiredRate = _rate;
        emit DesiredRateSet(_rate);
    }

    // 获取容忍的流动性迁移误差比例
    function getDesiredRate() public view returns(uint256) {
        return desiredRate;
    }

    // token地址排序
    function sortTokens(address _tokenA, address _tokenB) internal pure returns (address token0, address token1) {
        require(_tokenA != _tokenB, 'BakerySwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(token0 != address(0), 'BakerySwapLibrary: ZERO_ADDRESS');
    }

    // 提取LP代币
    function split(
        address _router, 
        address _tokenA, 
        address _tokenB, 
        uint256 _liquidity) internal returns (uint256 amountA, uint256 amountB) {
        require(_router != address(0), "Invalid liquity factory contract.");
        address factory = ISwapV2Router(_router).factory();
        address pair = ISwapV2Factory(factory).getPair(_tokenA, _tokenB);

        // require(ISwapV2Pair(pair).transferFrom(msg.sender, pair, _liquidity), 'TRANSFER_FROM_FAILED');
        ISwapV2Pair(pair).transferFrom(msg.sender, pair, _liquidity);
        (amountA, amountB) = ISwapV2Pair(pair).burn(address(this));

        // (amountA, amountB) = ISwapV2Router(_router).removeLiquidity(
        //     _tokenA,
        //     _tokenB,
        //     _liquidity,
        //     0,
        //     0,
        //     msg.sender,
        //     _deadline
        // );
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
        uint256 amountADesired = _amountADesired.mul(desiredRate).div(1e18);
        uint256 amountBDesired = _amountBDesired.mul(desiredRate).div(1e18);
        TransferHelper.safeApprove(_tokenA, _router, amountADesired);
        TransferHelper.safeApprove(_tokenB, _router, amountBDesired);
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
        uint256 _oldLiquidity) external returns (uint256, uint256, uint256) {
        (address token0, address token1) = sortTokens(_tokenA, _tokenB);
        (uint256 amountA, uint256 amountB) = split(
            _oldRouter,
            token0,
            token1,
            _oldLiquidity
        );

        (uint256 newAmountA, uint256 newAmountB, uint256 newLiquidity) = compose(
            _newRouter,
            token0,
            token1,
            amountA,
            amountB,
            uint256(-1)
        );

        uint256 remainAmountA = newAmountA > amountA ? newAmountA.sub(amountA) : amountA.sub(newAmountA);
        uint256 remainAmountB = newAmountB > amountB ? newAmountB.sub(amountB) : amountB.sub(newAmountB);
        return (remainAmountA, remainAmountB, newLiquidity);
    }
}
