// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AuctionV1} from "../../src/auction/AuctionV1.sol";
import {NFTMarketplace} from "../../src/nft/NFTMarketplace.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IAuction} from "../../src/interface/IAuction.sol";

/**
 * @title AuctionTest
 * @notice Auction 合约基本功能测试
 */
contract AuctionTest is Test {
    AuctionV1 auctionImplementation;
    ERC1967Proxy proxy;
    AuctionV1 auction; // 代理合约接口

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
        // 部署 NFT 合约 (name, symbol, owner)
        nft = new NFTMarketplace("Test NFT", "TNFT", owner);

        // 部署 Mock ERC20
        token = new MockERC20("USDC", "USDC", 18);

        // 部署 Mock 价格预言机
        ethPriceFeed = new MockPriceFeed(3000 * 1e8); // $3000 per ETH
        tokenPriceFeed = new MockPriceFeed(1 * 1e8); // $1 per token

        // 部署 Auction 实现合约
        auctionImplementation = new AuctionV1();

        // 编码初始化调用数据
        bytes memory initData = abi.encodeWithSelector(
            bytes4(keccak256("initialize(address,address,address,uint256)")),
            owner,
            address(ethPriceFeed),
            feeRecipient,
            250 // 2.5% 手续费
        );

        // 部署代理合约
        proxy = new ERC1967Proxy(address(auctionImplementation), initData);

        // 通过代理地址创建合约实例
        auction = AuctionV1(payable(address(proxy)));

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

    // ========== 测试：初始化 ==========

    function test_InitialState() public view {
        assertEq(auction.owner(), owner);
        assertEq(auction.feeRate(), 250);
        assertEq(auction.feeRecipient(), feeRecipient);
    }

    // ========== 测试：创建拍卖 ==========

    function test_CreateAuction() public {
        // 铸造 NFT
        tokenId = _mintNftTo(seller);

        // 授权拍卖合约
        vm.prank(seller);
        nft.setApprovalForAll(address(auction), true);

        // 创建拍卖
        uint256 duration = 1 days;
        uint256 minBidUSD = 100 * 1e18; // $100

        vm.prank(seller);
        auctionId = auction.createAuction(
            address(nft),
            tokenId,
            duration,
            minBidUSD,
            address(0) // 使用 ETH
        );

        // 验证拍卖信息
        IAuction.AuctionInfo memory auctionInfo = auction.getAuction(auctionId);
        assertEq(auctionInfo.seller, seller);
        assertEq(auctionInfo.nftContract, address(nft));
        assertEq(auctionInfo.tokenId, tokenId);
        assertEq(auctionInfo.startTime, block.timestamp);
        assertEq(auctionInfo.endTime, block.timestamp + duration);
        assertEq(auctionInfo.minBid, minBidUSD);
        assertEq(auctionInfo.paymentToken, address(0));
        assertEq(uint(auctionInfo.status), uint(IAuction.AuctionStatus.Active));

        // 验证 NFT 已转移到合约
        assertEq(nft.ownerOf(tokenId), address(auction));
    }

    function test_CreateAuctionFails_InvalidNFTContract() public {
        vm.expectRevert("Invalid NFT contract");
        auction.createAuction(address(0), 0, 1 days, 100 * 1e18, address(0));
    }

    function test_CreateAuctionFails_NotNFTOwner() public {
        uint256 mintedTokenId = _mintNftTo(seller);

        vm.prank(bidder1);
        vm.expectRevert("Not NFT owner");
        auction.createAuction(
            address(nft),
            mintedTokenId,
            1 days,
            100 * 1e18,
            address(0)
        );
    }

    // ========== 测试：ETH 出价 ==========

    function test_PlaceBid() public {
        // 铸造 NFT 并创建拍卖
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        // 出价
        uint256 bidAmount = 1 ether;
        vm.prank(bidder1);
        auction.placeBid{value: bidAmount}(auctionId);

        // 验证出价
        IAuction.Bid memory highestBid = auction.getHighestBid(auctionId);
        assertEq(highestBid.bidder, bidder1);
        assertEq(highestBid.amount, bidAmount);
        assertEq(highestBid.isETH, true);
    }

    function test_PlaceBidFails_BidTooLow() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        // 0.03 ETH ≈ $90，低于最低 $100
        uint256 bidAmount = 0.03 ether;
        vm.prank(bidder1);
        vm.expectRevert("Bid too low");
        auction.placeBid{value: bidAmount}(auctionId);
    }

    function test_PlaceBidFails_BidNotHigher() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        // 第一次出价
        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(auctionId);

        // 第二次出价相同金额
        vm.prank(bidder2);
        vm.expectRevert("Bid must be higher than current highest");
        auction.placeBid{value: 1 ether}(auctionId);
    }

    function test_Outbid_UpdatesPendingWithdrawal() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        // 第一次出价
        uint256 bid1Amount = 1 ether;
        vm.prank(bidder1);
        auction.placeBid{value: bid1Amount}(auctionId);

        // 第二次出价更高
        uint256 bid2Amount = 2 ether;
        vm.prank(bidder2);
        auction.placeBid{value: bid2Amount}(auctionId);

        // bidder1 应该有待提取的余额
        // 无法直接验证私有变量，但可以通过 withdraw 验证
    }

    // ========== 测试：ERC20 出价 ==========

    function test_PlaceBidWithToken() public {
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

        // 出价
        uint256 bidAmount = 100 * 1e18;
        vm.startPrank(bidder1);
        token.approve(address(auction), bidAmount);
        auction.placeBidWithToken(auctionId, bidAmount);
        vm.stopPrank();

        // 验证出价
        IAuction.Bid memory highestBid = auction.getHighestBid(auctionId);
        assertEq(highestBid.bidder, bidder1);
        assertEq(highestBid.amount, bidAmount);
        assertEq(highestBid.isETH, false);
    }

    function test_PlaceBidWithTokenFails_PriceFeedNotSet() public {
        // 创建使用未设置价格预言机的代币拍卖
        uint256 nftTokenId = _mintNftTo(seller);
        MockERC20 unknownToken = new MockERC20("Unknown", "UNK", 18);
        vm.prank(seller);
        nft.setApprovalForAll(address(auction), true);
        vm.prank(seller);
        auctionId = auction.createAuction(
            address(nft),
            nftTokenId,
            1 days,
            100 * 1e18,
            address(unknownToken)
        );

        vm.prank(bidder1);
        vm.expectRevert("Price feed not set");
        auction.placeBidWithToken(auctionId, 100 * 1e18);
    }

    // ========== 测试：结束拍卖 ==========

    function test_EndAuction_WithBids() public {
        // 创建拍卖并出价
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        uint256 winningBid = 1 ether;
        vm.prank(bidder1);
        auction.placeBid{value: winningBid}(auctionId);

        // 快进到拍卖结束
        vm.warp(block.timestamp + 1 days + 1);

        // 结束拍卖
        auction.endAuction(auctionId);

        // 验证状态
        IAuction.AuctionInfo memory auctionInfo = auction.getAuction(auctionId);
        assertEq(uint(auctionInfo.status), uint(IAuction.AuctionStatus.Ended));

        // 验证 NFT 转移
        assertEq(nft.ownerOf(nftTokenId), bidder1);

        // 验证卖家收到资金（1 ETH - 2.5% 手续费）
        // 手续费 = 1 * 250 / 10000 = 0.025 ETH
        // 卖家得到 = 1 - 0.025 = 0.975 ETH
        assertEq(seller.balance, 100 ether + 0.975 ether);

        // 验证手续费接收者收到手续费
        assertEq(feeRecipient.balance, 0.025 ether);
    }

    function test_EndAuction_NoBids() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        // 快进到拍卖结束
        vm.warp(block.timestamp + 1 days + 1);

        // 结束拍卖
        auction.endAuction(auctionId);

        // 验证 NFT 退还给卖家
        assertEq(nft.ownerOf(nftTokenId), seller);
    }

    function test_EndAuctionFails_NotEnded() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        vm.expectRevert("Auction not ended");
        auction.endAuction(auctionId);
    }

    // ========== 测试：取消拍卖 ==========

    function test_CancelAuction() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        vm.prank(seller);
        auction.cancelAuction(auctionId);

        // 验证状态
        IAuction.AuctionInfo memory auctionInfo = auction.getAuction(auctionId);
        assertEq(
            uint(auctionInfo.status),
            uint(IAuction.AuctionStatus.Cancelled)
        );

        // 验证 NFT 退还给卖家
        assertEq(nft.ownerOf(nftTokenId), seller);
    }

    function test_CancelAuctionFails_NotSeller() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        vm.prank(bidder1);
        vm.expectRevert("Not seller");
        auction.cancelAuction(auctionId);
    }

    function test_CancelAuctionFails_HasBids() public {
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        vm.prank(bidder1);
        auction.placeBid{value: 1 ether}(auctionId);

        vm.prank(seller);
        vm.expectRevert("Cannot cancel auction with bids");
        auction.cancelAuction(auctionId);
    }

    // ========== 测试：提取资金 ==========

    function test_WithdrawETH() public {
        // 创建拍卖并出价
        uint256 nftTokenId = _mintNftTo(seller);
        _createEthAuction(seller, nftTokenId, 1 days, 100 * 1e18);

        uint256 bid1Amount = 1 ether;
        vm.prank(bidder1);
        auction.placeBid{value: bid1Amount}(auctionId);

        uint256 bid2Amount = 2 ether;
        vm.prank(bidder2);
        auction.placeBid{value: bid2Amount}(auctionId);

        // bidder1 应该有 1 ether 待提取
        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder1);
        auction.withdrawETH();

        assertEq(bidder1.balance, balanceBefore + bid1Amount);
    }

    function test_WithdrawToken() public {
        // 创建 ERC20 拍卖并出价
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

        uint256 bid1Amount = 100 * 1e18;
        vm.startPrank(bidder1);
        token.approve(address(auction), bid1Amount);
        auction.placeBidWithToken(auctionId, bid1Amount);
        vm.stopPrank();

        uint256 bid2Amount = 200 * 1e18;
        vm.startPrank(bidder2);
        token.approve(address(auction), bid2Amount);
        auction.placeBidWithToken(auctionId, bid2Amount);
        vm.stopPrank();

        // bidder1 应该有 bid1Amount 待提取
        uint256 balanceBefore = token.balanceOf(bidder1);
        vm.prank(bidder1);
        auction.withdrawToken(address(token));

        assertEq(token.balanceOf(bidder1), balanceBefore + bid1Amount);
    }

    // ========== 测试：管理函数 ==========

    function test_SetFeeRate() public {
        auction.setFeeRate(500); // 5%

        assertEq(auction.feeRate(), 500);
    }

    function test_SetFeeRateFails_TooHigh() public {
        vm.expectRevert("Fee rate too high");
        auction.setFeeRate(1001);
    }

    function test_SetFeeRecipient() public {
        address newRecipient = address(0x5);
        auction.setFeeRecipient(newRecipient);

        assertEq(auction.feeRecipient(), newRecipient);
    }

    function test_SetFeeRecipientFails_ZeroAddress() public {
        vm.expectRevert("Invalid fee recipient");
        auction.setFeeRecipient(address(0));
    }

    function test_SetTokenPriceFeed() public {
        MockPriceFeed newFeed = new MockPriceFeed(2 * 1e8);
        auction.setTokenPriceFeed(address(token), address(newFeed));

        // 无法直接验证 mapping，但不报错即成功
    }

    function test_SetTokenPriceFeedFails_InvalidToken() public {
        vm.expectRevert("Invalid token");
        auction.setTokenPriceFeed(address(0), address(tokenPriceFeed));
    }

    // ========== 辅助函数 ==========

    // 铸造 NFT 给指定地址（只有 owner 可以铸造）
    function _mintNftTo(address to) internal returns (uint256) {
        return nft.mint(to, "ipfs://test");
    }

    function _createEthAuction(
        address _seller,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _minBidUSD
    ) internal {
        // 先授权拍卖合约可以操作 NFT
        vm.prank(_seller);
        nft.setApprovalForAll(address(auction), true);

        // 再创建拍卖
        vm.prank(_seller);
        auctionId = auction.createAuction(
            address(nft),
            _tokenId,
            _duration,
            _minBidUSD,
            address(0) // ETH
        );
    }
}

// ========== Mock 合约 ==========

contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
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
        // forge-lint: disable-next-line(unsafe-typecast)
        return (1, int256(price), block.timestamp, block.timestamp, 1);
        // casting to 'int256' is safe because price values are always positive and well within int256 range
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

    function getRoundData(
        uint80
    )
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
        // forge-lint: disable-next-line(unsafe-typecast)
        return (1, int256(price), block.timestamp, block.timestamp, 1);
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }
}
