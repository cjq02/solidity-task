// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceConverter
 * @dev 使用 Chainlink 预言机进行价格转换的工具库
 */
library PriceConverter {
    struct BidValue {
        uint256 amount;
        bool isETH;
        AggregatorV3Interface priceFeed;
    }
    /**
     * @dev 获取 ETH/USD 价格
     */
    function getETHPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (
            uint80 _roundId,
            int256 price,
            uint256 _startedAt,
            uint256 updatedAt,
            uint80 _answeredInRound
        ) = priceFeed.latestRoundData();
        _roundId;
        _startedAt;
        _answeredInRound;
        // 验证价格有效性
        require(price > 0, "Invalid price");
        require(updatedAt > 0, "Round not updated");
        // price 是 8 位小数，例如 2000 * 10^8 = 2000 USD
        return uint256(price);
    }
    
    /**
     * @dev 将 ETH 金额转换为 USD
     * @notice 使用 using for 语法，AggregatorV3Interface 作为第一个参数
     */
    function getETHAmountInUSD(
        AggregatorV3Interface priceFeed,
        uint256 ethAmount
    ) internal view returns (uint256) {
        uint256 ethPrice = getETHPrice(priceFeed);
        return (ethAmount * ethPrice) / 1e8;
    }

    /**
     * @dev 将 ERC20 代币金额转换为 USD
     * @notice 使用 using for 语法，AggregatorV3Interface 作为第一个参数
     */
    function getTokenAmountInUSD(
        AggregatorV3Interface priceFeed,
        uint256 tokenAmount
    ) internal view returns (uint256) {
        uint256 tokenPrice = getETHPrice(priceFeed);
        return (tokenAmount * tokenPrice) / 1e8;
    }
    
    /**
     * @dev 将出价值转换为 USD（统一转换入口）
     * @param bid 出价值（自动判断 ETH 或 Token）
     * @return usdValue USD 金额（18 位小数）
     */
    function getUSDValue(BidValue memory bid) internal view returns (uint256) {
        return bid.isETH
            ? getETHAmountInUSD(bid.priceFeed, bid.amount)
            : getTokenAmountInUSD(bid.priceFeed, bid.amount);
    }

    /**
     * @dev 比较两个出价的 USD 价值
     * @param bid1 第一个出价
     * @param bid2 第二个出价
     * @return 如果第一个出价更高返回 true
     */
    function compareBids(
        BidValue memory bid1,
        BidValue memory bid2
    ) internal view returns (bool) {
        return getUSDValue(bid1) > getUSDValue(bid2);
    }

    /**
     * @dev 创建 ETH 出价（辅助函数）
     * @param amount ETH 金额
     * @param priceFeed ETH/USD 价格预言机
     * @return bid ETH 出价值
     */
    function ethBid(
        uint256 amount,
        AggregatorV3Interface priceFeed
    ) internal pure returns (BidValue memory) {
        return BidValue({amount: amount, isETH: true, priceFeed: priceFeed});
    }

    /**
     * @dev 创建 Token 出价（辅助函数）
     * @param amount Token 金额（必须是 18 位小数）
     * @param priceFeed Token/USD 价格预言机
     * @return bid Token 出价值
     */
    function tokenBid(
        uint256 amount,
        AggregatorV3Interface priceFeed
    ) internal pure returns (BidValue memory) {
        return BidValue({amount: amount, isETH: false, priceFeed: priceFeed});
    }
}