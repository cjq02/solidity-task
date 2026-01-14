// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AuctionV2} from "../src/auction/AuctionV2.sol";

/**
 * @title InteractAuction
 * @notice 与 Auction V2 合约交互的示例脚本
 */
contract InteractAuction is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 从环境变量读取代理地址
        address payable proxyAddress = payable(vm.envAddress("PROXY_ADDRESS"));

        // 通过代理地址创建合约实例（使用 V2 接口）
        AuctionV2 auction = AuctionV2(proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        // 示例 1: 添加手续费层级（V2 功能）
        auction.addFeeTier(1000 * 1e18, 200);
        console.log("Added fee tier: >= $1000 USD, fee rate 2%");

        // 示例 2: 设置代币价格预言机
        // address usdcPriceFeed = 0x...; // 替换为实际地址
        // auction.setTokenPriceFeed(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, usdcPriceFeed);

        // 示例 3: 查询合约信息
        uint256 feeRate = auction.feeRate();
        console.log("Current fee rate:", feeRate);

        address feeRecipient = auction.feeRecipient();
        console.log("Fee recipient:", feeRecipient);

        // 示例 4: 获取手续费层级
        AuctionV2.FeeTier[] memory tiers = auction.getFeeTiers();
        console.log("Number of fee tiers:", tiers.length);

        vm.stopBroadcast();
    }
}
