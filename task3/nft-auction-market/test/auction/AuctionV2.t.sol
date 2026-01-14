// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AuctionV2} from "../../src/auction/AuctionV2.sol";
import {NFTMarketplace} from "../../src/nft/NFTMarketplace.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IAuction} from "../../src/interface/IAuction.sol";

/**
 * @title AuctionV2Test
 * @notice AuctionV2 合约功能测试，重点测试动态手续费功能
 */
contract AuctionV2Test is Test {
    AuctionV2 auctionImplementation;
    ERC1967Proxy proxy;
    AuctionV2 auction; // 代理合约接口

    NFTMarketplace nft;
    MockERC20 token;
    MockPriceFeed ethPriceFeed;
    MockPriceFeed tokenPriceFeed;

    address owner = address(this);
    address seller = address(0x1);
    address bidder1 = address(0x2);
    address bidder2 = address(0x3);
    address feeRecipient = address(0x4);

    uint256 auctionId;
    uint256 tokenId;

    function setUp() public {
        // 部署 NFT 合约
        nft = new NFTMarketplace("Test NFT", "TNFT", owner);

        // 部署 Mock ERC20
        token = new MockERC20("USDC", "USDC", 18);

        // 部署 Mock 价格预言机
        ethPriceFeed = new MockPriceFeed(3000 * 1e8); // $3000 per ETH
        tokenPriceFeed = new MockPriceFeed(1 * 1e8); // $1 per token

        // 部署 AuctionV2 实现合约
        auctionImplementation = new AuctionV2();

        // 编码初始化调用数据
        bytes memory initData = abi.encodeWithSelector(
            bytes4(keccak256("initialize(address,address,address,uint256)")),
            owner,
            address(ethPriceFeed),
            feeRecipient,
            250 // 2.5% 默认手续费率
        );

        // 部署代理合约
        proxy = new ERC1967Proxy(
            address(auctionImplementation),
            initData
        );

        // 通过代理地址创建合约实例
        auction = AuctionV2(payable(address(proxy)));

        // 设置代币价格预言机
        auction.setTokenPriceFeed(address(token), address(tokenPriceFeed));

        // 给用户分配 ETH
        vm.deal(seller, 100 ether);
        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);

        // 给用户分配代币
        token.mint(seller, 100000 * 1e18);
        token.mint(bidder1, 100000 * 1e18);
        token.mint(bidder2, 100000 * 1e18);
    }

    // ========== 测试：初始化和默认手续费层级 ==========

    function test_InitialState() public view {
        assertEq(auction.owner(), owner);
        assertEq(auction.feeRate(), 250);
        assertEq(auction.feeRecipient(), feeRecipient);
    }

    function test_InitialFeeTier() public view {
        // 初始化后应该有一个默认的 fee tier
        AuctionV2.FeeTier[] memory feeTiers = auction.getFeeTiers();
        assertEq(feeTiers.length, 1);
        assertEq(feeTiers[0].minAmount, 0);
        assertEq(feeTiers[0].feeRate, 250); // 2.5%
    }

    // ========== 测试：手续费层级管理 ==========

    function test_AddFeeTier() public {
        auction.addFeeTier(1000 * 1e18, 300); // $1000 以上，3% 手续费

        AuctionV2.FeeTier[] memory feeTiers = auction.getFeeTiers();
        assertEq(feeTiers.length, 2);
        assertEq(feeTiers[1].minAmount, 1000 * 1e18);
        assertEq(feeTiers[1].feeRate, 300);
    }

    function test_AddMultipleFeeTiers() public {
        auction.addFeeTier(1000 * 1e18, 300); // $1000 以上，3%
        auction.addFeeTier(5000 * 1e18, 400); // $5000 以上，4%
        auction.addFeeTier(10000 * 1e18, 500); // $10000 以上，5%

        AuctionV2.FeeTier[] memory feeTiers = auction.getFeeTiers();
        assertEq(feeTiers.length, 4); // 包括默认的 0
    }

    function test_AddFeeTierFails_RateTooHigh() public {
        vm.expectRevert("Fee rate too high");
        auction.addFeeTier(1000 * 1e18, 1001);
    }

    function test_RemoveFeeTier() public {
        auction.addFeeTier(1000 * 1e18, 300);

        uint256 lengthBefore = auction.getFeeTiers().length;
        auction.removeFeeTier(1);

        assertEq(auction.getFeeTiers().length, lengthBefore - 1);
    }

    function test_RemoveFeeTierFails_InvalidIndex() public {
        vm.expectRevert("Invalid index");
        auction.removeFeeTier(999);
    }

    function test_UpdateFeeTier() public {
        auction.addFeeTier(1000 * 1e18, 300);

        auction.updateFeeTier(1, 2000 * 1e18, 350);

        AuctionV2.FeeTier[] memory feeTiers = auction.getFeeTiers();
        assertEq(feeTiers[1].minAmount, 2000 * 1e18);
        assertEq(feeTiers[1].feeRate, 350);
    }

    function test_UpdateFeeTierFails_InvalidIndex() public {
        vm.expectRevert("Invalid index");
        auction.updateFeeTier(999, 1000 * 1e18, 300);
    }

    function test_UpdateFeeTierFails_RateTooHigh() public {
        vm.expectRevert("Fee rate too high");
        auction.updateFeeTier(0, 0, 1001);
    }

    // ========== 测试：固定手续费计算（V1 兼容） ==========

    function test_CalculateFee_FixedRate() public view {
        // 使用默认手续费率 2.5%
        uint256 amount = 1 ether;
        uint256 fee = auction.calculateFee(amount, true, address(0));

        // 1 ETH * 250 / 10000 = 0.025 ETH
        assertEq(fee, 0.025 ether);
    }

    function test_CalculateFee_FixedRate_WithToken() public view {
        // ERC20 代币，$3000 的价值
        uint256 amount = 3000 * 1e18; // 3000 tokens，每个 $1
        uint256 fee = auction.calculateFee(amount, false, address(token));

        // 3000 * 250 / 10000 = 75 tokens
        assertEq(fee, 75 * 1e18);
    }

    // ========== 测试：动态手续费计算 ==========

    function test_CalculateFee_DynamicTiers_ETH() public {
        // 设置手续费层级：
        // $0 - $1000: 2.5%
        // $1000 - $5000: 3%
        // $5000+: 4%
        auction.addFeeTier(1000 * 1e18, 300);
        auction.addFeeTier(5000 * 1e18, 400);

        // 小额交易：0.1 ETH ≈ $300，应该用 2.5%
        uint256 fee1 = auction.calculateFee(0.1 ether, true, address(0));
        assertEq(fee1, (0.1 ether * 250) / 10000);

        // 中额交易：1 ETH ≈ $3000，应该用 3%
        uint256 fee2 = auction.calculateFee(1 ether, true, address(0));
        assertEq(fee2, (1 ether * 300) / 10000);

        // 大额交易：3 ETH ≈ $9000，应该用 4%
        uint256 fee3 = auction.calculateFee(3 ether, true, address(0));
        assertEq(fee3, (3 ether * 400) / 10000);
    }

    function test_CalculateFee_DynamicTiers_Token() public {
        // 设置手续费层级
        auction.addFeeTier(1000 * 1e18, 300);
        auction.addFeeTier(5000 * 1e18, 400);

        // 小额交易：500 tokens ≈ $500，应该用 2.5%
        uint256 fee1 = auction.calculateFee(500 * 1e18, false, address(token));
        assertEq(fee1, (500 * 1e18 * 250) / 10000);

        // 中额交易：2000 tokens ≈ $2000，应该用 3%
        uint256 fee2 = auction.calculateFee(2000 * 1e18, false, address(token));
        assertEq(fee2, (2000 * 1e18 * 300) / 10000);

        // 大额交易：10000 tokens ≈ $10000，应该用 4%
        uint256 fee3 = auction.calculateFee(10000 * 1e18, false, address(token));
        assertEq(fee3, (10000 * 1e18 * 400) / 10000);
    }

    function test_CalculateFee_DynamicTiers_BoundaryValues() public {
        // 设置边界：$1000 开始 3%
        auction.addFeeTier(1000 * 1e18, 300);

        // 使用一个能被整除的金额来测试边界
        // $3000 = 1 ETH（当 ETH 价格为 $3000 时）
        uint256 amountAtBoundary = 1 ether;
        uint256 fee = auction.calculateFee(amountAtBoundary, true, address(0));
        // 应该使用 3% 费率（因为 >= $1000）
        assertEq(fee, (amountAtBoundary * 300) / 10000);
    }

    function test_CalculateFee_ZeroPriceFeed() public {
        MockERC20 unknownToken = new MockERC20("Unknown", "UNK", 18);

        vm.expectRevert("Price feed not set");
        auction.calculateFee(100 * 1e18, false, address(unknownToken));
    }

    // ========== 测试：拍卖流程使用动态手续费 ==========

    function test_EndAuction_WithDynamicFeeTier() public {
        // 设置手续费层级：$1000 以上 3%
        auction.addFeeTier(1000 * 1e18, 300);

        // 创建拍卖
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        // 出价 1 ETH ≈ $3000，应该用 3% 手续费
        uint256 winningBid = 1 ether;
        vm.prank(bidder1);
        auction.placeBid{value: winningBid}(auctionId);

        // 快进到拍卖结束
        vm.warp(block.timestamp + 1 days + 1);

        // 结束拍卖
        auction.endAuction(auctionId);

        // 验证手续费是 3%（不是默认的 2.5%）
        // 手续费 = 1 * 300 / 10000 = 0.03 ETH
        // 卖家得到 = 1 - 0.03 = 0.97 ETH
        assertEq(seller.balance, 100 ether + 0.97 ether);
        assertEq(feeRecipient.balance, 0.03 ether);
    }

    function test_EndAuction_WithHighestFeeTier() public {
        // 设置多层手续费
        auction.addFeeTier(1000 * 1e18, 300); // $1000+ : 3%
        auction.addFeeTier(5000 * 1e18, 500); // $5000+ : 5%

        // 创建拍卖
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        // 出价 3 ETH ≈ $9000，应该用 5% 手续费
        uint256 winningBid = 3 ether;
        vm.prank(bidder1);
        auction.placeBid{value: winningBid}(auctionId);

        // 快进到拍卖结束
        vm.warp(block.timestamp + 1 days + 1);

        // 记录余额
        uint256 sellerBalanceBefore = seller.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;

        // 结束拍卖
        auction.endAuction(auctionId);

        // 验证手续费是 5%
        uint256 expectedFee = (3 ether * 500) / 10000; // 0.15 ETH
        uint256 expectedSellerAmount = 3 ether - expectedFee; // 2.85 ETH

        assertEq(seller.balance - sellerBalanceBefore, expectedSellerAmount);
        assertEq(feeRecipient.balance - feeRecipientBalanceBefore, expectedFee);
    }

    function test_EndAuction_WithToken_DynamicFee() public {
        // 设置手续费层级
        auction.addFeeTier(1000 * 1e18, 300);

        // 创建 ERC20 拍卖
        uint256 nftTokenId = _mintNftTo(seller);
        vm.prank(seller);
        nft.setApprovalForAll(address(auction), true);
        vm.prank(seller);
        auctionId = auction.createAuction(
            address(nft),
            nftTokenId,
            1 days,
            100 * 1e18,
            address(token)
        );

        // 出价 2000 tokens ≈ $2000，应该用 3% 手续费
        uint256 winningBid = 2000 * 1e18;
        vm.startPrank(bidder1);
        token.approve(address(auction), winningBid);
        auction.placeBidWithToken(auctionId, winningBid);
        vm.stopPrank();

        // 快进到拍卖结束
        vm.warp(block.timestamp + 1 days + 1);

        // 记录余额
        uint256 sellerBalanceBefore = token.balanceOf(seller);
        uint256 feeRecipientBalanceBefore = token.balanceOf(feeRecipient);

        // 结束拍卖
        auction.endAuction(auctionId);

        // 验证手续费是 3%
        uint256 expectedFee = (2000 * 1e18 * 300) / 10000; // 60 tokens
        uint256 expectedSellerAmount = 2000 * 1e18 - expectedFee; // 1940 tokens

        assertEq(token.balanceOf(seller) - sellerBalanceBefore, expectedSellerAmount);
        assertEq(token.balanceOf(feeRecipient) - feeRecipientBalanceBefore, expectedFee);
    }

    // ========== 测试：继承的基础功能 ==========

    function test_CreateAuction() public {
        tokenId = _mintNftTo(seller);

        vm.prank(seller);
        nft.setApprovalForAll(address(auction), true);

        uint256 duration = 1 days;
        uint256 minBidUSD = 100 * 1e18;

        vm.prank(seller);
        auctionId = auction.createAuction(
            address(nft),
            tokenId,
            duration,
            minBidUSD,
            address(0)
        );

        IAuction.AuctionInfo memory auctionInfo = auction.getAuction(auctionId);
        assertEq(auctionInfo.seller, seller);
        assertEq(uint(auctionInfo.status), uint(IAuction.AuctionStatus.Active));
    }

    function test_PlaceBid() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        uint256 bidAmount = 1 ether;
        vm.prank(bidder1);
        auction.placeBid{value: bidAmount}(auctionId);

        IAuction.Bid memory highestBid = auction.getHighestBid(auctionId);
        assertEq(highestBid.bidder, bidder1);
        assertEq(highestBid.amount, bidAmount);
    }

    function test_CancelAuction() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        vm.prank(seller);
        auction.cancelAuction(auctionId);

        IAuction.AuctionInfo memory auctionInfo = auction.getAuction(auctionId);
        assertEq(uint(auctionInfo.status), uint(IAuction.AuctionStatus.Cancelled));
    }

    function test_WithdrawETH() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        uint256 bid1Amount = 1 ether;
        vm.prank(bidder1);
        auction.placeBid{value: bid1Amount}(auctionId);

        uint256 bid2Amount = 2 ether;
        vm.prank(bidder2);
        auction.placeBid{value: bid2Amount}(auctionId);

        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder1);
        auction.withdrawETH();

        assertEq(bidder1.balance, balanceBefore + bid1Amount);
    }

    // ========== 测试：FeeTier 边界情况 ==========

    function test_FeeTier_ExactAmount() public {
        // 测试金额刚好等于 minAmount 的情况
        auction.addFeeTier(1000 * 1e18, 300);

        // $3000 刚好触发第二层级（1 ETH）
        uint256 amountAtBoundary = 1 ether;
        uint256 fee = auction.calculateFee(amountAtBoundary, true, address(0));
        assertEq(fee, (amountAtBoundary * 300) / 10000);
    }

    function test_FeeTier_JustBelowBoundary() public {
        auction.addFeeTier(1000 * 1e18, 300);

        // $900 应该使用第一层级（2.5%）
        // 0.3 ETH = $900（当 ETH 为 $3000）
        uint256 amountJustBelow = 0.3 ether;
        uint256 fee = auction.calculateFee(amountJustBelow, true, address(0));
        assertEq(fee, (amountJustBelow * 250) / 10000);
    }

    function test_FeeTier_LargeAmount() public {
        // 测试超大金额
        auction.addFeeTier(100000 * 1e18, 600); // $100k+ : 6%

        uint256 largeAmount = 100 ether; // ≈ $300k
        uint256 fee = auction.calculateFee(largeAmount, true, address(0));
        assertEq(fee, (largeAmount * 600) / 10000);
    }

    // ========== 辅助函数 ==========

    function _mintNftTo(address to) internal returns (uint256) {
        return nft.mint(to, "ipfs://test");
    }

    function _createEthAuction(
        address _seller,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _minBidUSD
    ) internal {
        vm.prank(_seller);
        nft.setApprovalForAll(address(auction), true);

        vm.prank(_seller);
        auctionId = auction.createAuction(
            address(nft),
            _tokenId,
            _duration,
            _minBidUSD,
            address(0)
        );
    }
}

// ========== Mock 合约 ==========

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}

contract MockPriceFeed is AggregatorV3Interface {
    uint256 private price;
    uint8 private _decimals = 8;

    constructor(uint256 _price) {
        price = _price;
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, int256(price), block.timestamp, block.timestamp, 1);
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external pure override returns (string memory) {
        return "Mock Price Feed";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, int256(price), block.timestamp, block.timestamp, 1);
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }
}
