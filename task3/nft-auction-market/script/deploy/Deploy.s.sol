// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../src/auction/Auction.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployAuction
 * @notice 部署 Auction UUPS 代理合约
 */
contract DeployAuction is Script {
    Auction public implementation;
    ERC1967Proxy public proxy;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 部署实现合约
        implementation = new Auction();
        console.log("Implementation deployed at:", address(implementation));

        // 初始化参数
        address ethPriceFeed = vm.envAddress("ETH_PRICE_FEED");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT");
        uint256 feeRate = 250; // 2.5%

        // 编码初始化调用数据
        bytes memory initData = abi.encodeWithSelector(
            Auction.initialize.selector,
            deployer, // initialOwner
            ethPriceFeed,
            feeRecipient,
            feeRate
        );

        // 部署代理合约
        proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("Proxy deployed at:", address(proxy));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("Implementation:", address(implementation));
        console.log("Proxy:", address(proxy));
        console.log("Owner:", deployer);
    }
}
