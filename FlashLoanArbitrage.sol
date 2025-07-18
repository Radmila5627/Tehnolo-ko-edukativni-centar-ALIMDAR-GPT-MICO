// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlashLoanArbitrage is Ownable {
    address public oracle;
    address public usdc;
    address public profitReceiver;
    uint256 public mintThreshold = 10 * 1e6; // 10 USDC (6 decimals)
    uint256 public retainedPercent = 90;

    event ArbitrageExecuted(uint256 profit, address indexed receiver);
    event NFTMinted(address indexed user, uint256 value);

    constructor(address _oracle, address _usdc, address _profitReceiver) {
        oracle = _oracle;
        usdc = _usdc;
        profitReceiver = _profitReceiver;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function executeArbitrage(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");

        // Simulated oracle price check
        (, int price,,,) = AggregatorV3Interface(oracle).latestRoundData();
        require(price > 0, "Invalid price from oracle");

        // Simulate profit
        uint256 profit = amount / 100; // 1% profit
        uint256 toUser = (profit * (100 - retainedPercent)) / 100;
        uint256 toRetain = profit - toUser;

        IERC20(usdc).transfer(profitReceiver, toUser);
        // Retained in contract for reuse

        if (profit >= mintThreshold) {
            emit NFTMinted(profitReceiver, profit);
        }

        emit ArbitrageExecuted(profit, profitReceiver);
    }
}
