// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AuctionV2} from "../../src/auction/AuctionV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title UpgradeAuction
 * @notice 将 Auction 升级到 AuctionV2
 */
contract UpgradeAuction is Script {
    AuctionV2 public implementationV2;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // 从环境变量读取代理地址
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 部署 V2 实现合约
        implementationV2 = new AuctionV2();
        console.log("Implementation V2 deployed at:", address(implementationV2));

        // UUPS 升级：通过代理调用 upgradeTo
        // 使用 call 来绕过类型检查
        (bool success, ) = proxyAddress.call(
            abi.encodeWithSelector(UUPSUpgradeable.upgradeTo.selector, address(implementationV2))
        );
        require(success, "Upgrade failed");

        console.log("Proxy upgraded to V2 implementation");

        vm.stopBroadcast();

        console.log("\\n=== Upgrade Summary ===");
        console.log("Proxy:", proxyAddress);
        console.log("New Implementation:", address(implementationV2));
    }
}
