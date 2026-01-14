// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {NFTMarketplace} from "../../src/nft/NFTMarketplace.sol";

/**
 * @title DeployNFT
 * @notice 部署 NFTMarketplace 合约
 */
contract DeployNFT is Script {
    NFTMarketplace public nft;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 部署 NFTMarketplace 合约
        nft = new NFTMarketplace(
            "NFT Marketplace",
            "NFTM",
            deployer // initialOwner
        );
        console.log("NFTMarketplace deployed at:", address(nft));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("NFTMarketplace:", address(nft));
        console.log("Owner:", deployer);
    }
}
