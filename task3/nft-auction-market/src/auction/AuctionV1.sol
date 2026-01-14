// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Auction} from "./Auction.sol";

/**
 * @title AuctionV1
 * @dev NFT 拍卖合约 V1 版本，固定手续费率
 * @custom:security-contact security@example.com
 */
contract AuctionV1 is Auction {
    // V1 版本无需额外功能，直接继承基类即可
    // 基类 Auction 已经实现了所有核心功能
}
