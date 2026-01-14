// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "../interface/IAuction.sol";
import "../interface/INFTMarketplace.sol";
import "./PriceConverter.sol";

/**
 * @title AuctionV2
 * @dev NFT 拍卖合约升级版，添加动态手续费计算功能
 * @custom:security-contact security@example.com
 */
contract AuctionV2 is
    Initializable,
    IAuction,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    using PriceConverter for AggregatorV3Interface;

    // ========== 状态变量（与 V1 保持兼容） ==========

    uint256 private _auctionIdCounter;
    mapping(uint256 => IAuction.AuctionInfo) private _auctions;
    mapping(uint256 => IAuction.Bid[]) private _bids;
    mapping(uint256 => uint256) private _highestBidIndex;
    mapping(address => uint256) private _pendingETHWithdrawals;
    mapping(address => mapping(address => uint256)) private _pendingTokenWithdrawals;

    AggregatorV3Interface public ethPriceFeed;
    mapping(address => AggregatorV3Interface) public tokenPriceFeeds;
    uint256 public feeRate;
    address public feeRecipient;

    // ========== V2 新增：动态手续费配置 ==========

    struct FeeTier {
        uint256 minAmount; // 最小金额（USD，18 位小数）
        uint256 feeRate; // 手续费率（基点）
    }

    FeeTier[] public feeTiers;

    // ========== 修饰符 ==========

    modifier onlyActiveAuction(uint256 auctionId) {
        require(
            _auctions[auctionId].status == IAuction.AuctionStatus.Active,
            "Auction not active"
        );
        require(
            block.timestamp >= _auctions[auctionId].startTime,
            "Auction not started"
        );
        require(block.timestamp < _auctions[auctionId].endTime, "Auction ended");
        _;
    }

    // ========== UUPS 升级 ==========

    /// @notice UUPS 升级授权函数（只有 owner 可以升级）
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // ========== 初始化 ==========

    /// @notice 初始化合约（替代 constructor）
    function initialize(
        address initialOwner,
        address _ethPriceFeed,
        address _feeRecipient,
        uint256 _feeRate
    ) public initializer {
        require(_ethPriceFeed != address(0), "Invalid price feed");
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_feeRate <= 1000, "Fee rate too high");

        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _transferOwnership(initialOwner);

        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        feeRecipient = _feeRecipient;
        feeRate = _feeRate;

        // V2 新增：初始化默认手续费层级
        feeTiers.push(FeeTier({minAmount: 0, feeRate: _feeRate}));
    }

    // ========== 拍卖管理 ==========

    /**
     * @notice 创建拍卖
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 minBidUSD,
        address paymentToken
    ) external returns (uint256) {
        require(nftContract != address(0), "Invalid NFT contract");
        require(duration > 0, "Invalid duration");
        require(minBidUSD > 0, "Invalid min bid");

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 auctionId = _auctionIdCounter++;

        _auctions[auctionId] = AuctionInfo({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            minBid: minBidUSD,
            paymentToken: paymentToken,
            status: IAuction.AuctionStatus.Active
        });

        emit AuctionCreated(
            auctionId,
            msg.sender,
            nftContract,
            tokenId,
            _auctions[auctionId].startTime,
            _auctions[auctionId].endTime,
            minBidUSD
        );

        return auctionId;
    }

    /**
     * @notice 使用 ETH 出价
     */
    function placeBid(uint256 auctionId) external payable onlyActiveAuction(auctionId) nonReentrant {
        require(msg.value > 0, "Bid amount must be greater than 0");

        AuctionInfo storage auction = _auctions[auctionId];
        require(auction.paymentToken == address(0), "This auction accepts tokens, not ETH");

        uint256 usdValue = ethPriceFeed.getETHAmountInUSD(msg.value);
        require(usdValue >= auction.minBid, "Bid too low");

        if (_bids[auctionId].length > 0) {
            Bid memory currentHighest = _bids[auctionId][_highestBidIndex[auctionId]];
            uint256 currentHighestUSD = ethPriceFeed.getETHAmountInUSD(currentHighest.amount);
            require(usdValue > currentHighestUSD, "Bid must be higher than current highest");
            _pendingETHWithdrawals[currentHighest.bidder] += currentHighest.amount;
        }

        _bids[auctionId].push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            isETH: true
        }));

        _highestBidIndex[auctionId] = _bids[auctionId].length - 1;

        emit BidPlaced(auctionId, msg.sender, msg.value, true);
    }

    /**
     * @notice 使用 ERC20 代币出价
     */
    function placeBidWithToken(uint256 auctionId, uint256 amount) external onlyActiveAuction(auctionId) nonReentrant {
        require(amount > 0, "Bid amount must be greater than 0");

        AuctionInfo storage auction = _auctions[auctionId];
        require(auction.paymentToken != address(0), "This auction accepts ETH, not tokens");
        require(address(tokenPriceFeeds[auction.paymentToken]) != address(0), "Price feed not set");

        uint8 decimals = IERC20Metadata(auction.paymentToken).decimals();
        require(decimals == 18, "Token decimals must be 18");

        uint256 usdValue = tokenPriceFeeds[auction.paymentToken].getTokenAmountInUSD(amount);
        require(usdValue >= auction.minBid, "Bid too low");

        if (_bids[auctionId].length > 0) {
            Bid memory currentHighest = _bids[auctionId][_highestBidIndex[auctionId]];
            uint256 currentHighestUSD = tokenPriceFeeds[auction.paymentToken].getTokenAmountInUSD(currentHighest.amount);
            require(usdValue > currentHighestUSD, "Bid must be higher than current highest");
            _pendingTokenWithdrawals[currentHighest.bidder][auction.paymentToken] += currentHighest.amount;
        }

        _bids[auctionId].push(Bid({
            bidder: msg.sender,
            amount: amount,
            timestamp: block.timestamp,
            isETH: false
        }));

        _highestBidIndex[auctionId] = _bids[auctionId].length - 1;

        IERC20(auction.paymentToken).safeTransferFrom(msg.sender, address(this), amount);

        emit BidPlaced(auctionId, msg.sender, amount, false);
    }

    /**
     * @notice 结束拍卖
     */
    function endAuction(uint256 auctionId) external nonReentrant {
        AuctionInfo storage auction = _auctions[auctionId];
        require(auction.status == IAuction.AuctionStatus.Active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");

        auction.status = IAuction.AuctionStatus.Ended;

        if (_bids[auctionId].length == 0) {
            IERC721(auction.nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);
            emit AuctionEnded(auctionId, address(0), 0);
            return;
        }

        Bid memory winningBid = _bids[auctionId][_highestBidIndex[auctionId]];

        IERC721(auction.nftContract).safeTransferFrom(address(this), winningBid.bidder, auction.tokenId);

        // V2 改进：使用动态手续费计算
        uint256 fee = calculateFee(winningBid.amount, winningBid.isETH, auction.paymentToken);
        uint256 sellerAmount = winningBid.amount - fee;

        if (winningBid.isETH) {
            (bool success1, ) = payable(auction.seller).call{value: sellerAmount}("");
            require(success1, "ETH transfer to seller failed");
            (bool success2, ) = payable(feeRecipient).call{value: fee}("");
            require(success2, "ETH transfer to fee recipient failed");
        } else {
            IERC20(auction.paymentToken).safeTransfer(auction.seller, sellerAmount);
            IERC20(auction.paymentToken).safeTransfer(feeRecipient, fee);
        }

        emit AuctionEnded(auctionId, winningBid.bidder, winningBid.amount);
    }

    /**
     * @notice 取消拍卖（仅卖家）
     */
    function cancelAuction(uint256 auctionId) external {
        AuctionInfo storage auction = _auctions[auctionId];
        require(auction.status == IAuction.AuctionStatus.Active, "Auction not active");
        require(auction.seller == msg.sender, "Not seller");
        require(_bids[auctionId].length == 0, "Cannot cancel auction with bids");

        auction.status = IAuction.AuctionStatus.Cancelled;

        IERC721(auction.nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);

        emit AuctionCancelled(auctionId);
    }

    // ========== 查询函数 ==========

    /**
     * @notice 获取拍卖信息
     */
    function getAuction(uint256 auctionId) external view returns (IAuction.AuctionInfo memory) {
        return _auctions[auctionId];
    }

    /**
     * @notice 获取最高出价
     */
    function getHighestBid(uint256 auctionId) external view returns (IAuction.Bid memory) {
        if (_bids[auctionId].length == 0) {
            return Bid({bidder: address(0), amount: 0, timestamp: 0, isETH: false});
        }
        return _bids[auctionId][_highestBidIndex[auctionId]];
    }

    /**
     * @notice 获取所有出价
     */
    function getAllBids(uint256 auctionId) external view returns (IAuction.Bid[] memory) {
        return _bids[auctionId];
    }

    // ========== 管理函数 ==========

    /**
     * @notice 设置代币价格预言机
     */
    function setTokenPriceFeed(address token, address priceFeed) external onlyOwner {
        require(token != address(0), "Invalid token");
        require(priceFeed != address(0), "Invalid price feed");
        tokenPriceFeeds[token] = AggregatorV3Interface(priceFeed);
    }

    /**
     * @notice 设置手续费率
     */
    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 1000, "Fee rate too high");
        feeRate = _feeRate;
    }

    /**
     * @notice 设置手续费接收者
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    // ========== V2 新增：动态手续费功能 ==========

    /**
     * @notice 添加手续费层级
     */
    function addFeeTier(uint256 minAmount, uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 1000, "Fee rate too high");
        feeTiers.push(FeeTier({minAmount: minAmount, feeRate: _feeRate}));
    }

    /**
     * @notice 移除手续费层级
     */
    function removeFeeTier(uint256 index) external onlyOwner {
        require(index < feeTiers.length, "Invalid index");
        feeTiers[index] = feeTiers[feeTiers.length - 1];
        feeTiers.pop();
    }

    /**
     * @notice 更新手续费层级
     */
    function updateFeeTier(uint256 index, uint256 minAmount, uint256 _feeRate) external onlyOwner {
        require(index < feeTiers.length, "Invalid index");
        require(_feeRate <= 1000, "Fee rate too high");
        feeTiers[index] = FeeTier({minAmount: minAmount, feeRate: _feeRate});
    }

    /**
     * @notice 获取所有手续费层级
     */
    function getFeeTiers() external view returns (FeeTier[] memory) {
        return feeTiers;
    }

    /**
     * @notice 计算手续费（支持动态手续费）
     * @dev V2 新增：修复了原版本 ERC20 手续费计算为 0 的 bug
     */
    function calculateFee(
        uint256 amount,
        bool isETH,
        address paymentToken
    ) public view returns (uint256) {
        // 计算 USD 价值
        uint256 usdValue;
        if (isETH) {
            usdValue = ethPriceFeed.getETHAmountInUSD(amount);
        } else {
            // V2 修复：正确计算 ERC20 代币的 USD 价值
            require(address(tokenPriceFeeds[paymentToken]) != address(0), "Price feed not set");
            usdValue = tokenPriceFeeds[paymentToken].getTokenAmountInUSD(amount);
        }

        // 查找适用的手续费层级
        uint256 applicableFeeRate = feeRate;
        for (uint256 i = feeTiers.length; i > 0; i--) {
            if (usdValue >= feeTiers[i - 1].minAmount) {
                applicableFeeRate = feeTiers[i - 1].feeRate;
                break;
            }
        }

        return (amount * applicableFeeRate) / 10000;
    }

    // ========== 提现函数 ==========

    /**
     * @notice 提取待退还的 ETH
     */
    function withdrawETH() external nonReentrant {
        uint256 amount = _pendingETHWithdrawals[msg.sender];
        require(amount > 0, "No ETH to withdraw");
        _pendingETHWithdrawals[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");
        emit Withdrawn(msg.sender, amount, true);
    }

    /**
     * @notice 提取待退还的 ERC20 代币
     */
    function withdrawToken(address token) external nonReentrant {
        uint256 amount = _pendingTokenWithdrawals[msg.sender][token];
        require(amount > 0, "No tokens to withdraw");
        _pendingTokenWithdrawals[msg.sender][token] = 0;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, false);
    }

    /**
     * @notice 接收 ETH
     */
    receive() external payable {
        revert("Use placeBid() function");
    }
}
