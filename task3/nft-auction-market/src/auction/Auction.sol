// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "../interface/IAuction.sol";
import "../interface/INFTMarketplace.sol";
import "./PriceConverter.sol";

/**
 * @title Auction
 * @dev NFT 拍卖合约，支持 ETH 和 ERC20 出价
 */
contract Auction is IAuction, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using PriceConverter for AggregatorV3Interface;
    
    // 拍卖 ID 计数器
    uint256 private _auctionIdCounter;
    
    // 映射：auctionId => AuctionInfo
    mapping(uint256 => IAuction.AuctionInfo) public auctions;
    
    // 映射：auctionId => Bid[]
    mapping(uint256 => IAuction.Bid[]) public bids;
    
    // 映射：auctionId => 最高出价索引
    mapping(uint256 => uint256) public highestBidIndex;
    
    // Chainlink 价格预言机地址
    AggregatorV3Interface public ethPriceFeed;
    
    // 映射：tokenAddress => priceFeed
    mapping(address => AggregatorV3Interface) public tokenPriceFeeds;
    
    // 手续费率（基点，10000 = 100%）
    uint256 public feeRate; // 例如 250 = 2.5%
    
    // 手续费接收地址
    address public feeRecipient;
    
    // 动态手续费配置
    struct FeeTier {
        uint256 minAmount;  // 最小金额（USD，18 位小数）
        uint256 feeRate;    // 手续费率（基点）
    }
    
    FeeTier[] public feeTiers;
    
    modifier onlyActiveAuction(uint256 auctionId) {
        require(auctions[auctionId].status == IAuction.AuctionStatus.Active, "Auction not active");
        require(block.timestamp >= auctions[auctionId].startTime, "Auction not started");
        require(block.timestamp < auctions[auctionId].endTime, "Auction ended");
        _;
    }
    
    constructor(
        address initialOwner,
        address _ethPriceFeed,
        address _feeRecipient,
        uint256 _feeRate
    ) Ownable(initialOwner) {
        require(_ethPriceFeed != address(0), "Invalid price feed");
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_feeRate <= 1000, "Fee rate too high"); // 最大 10%
        
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        feeRecipient = _feeRecipient;
        feeRate = _feeRate;
        
        // 初始化默认手续费层级
        feeTiers.push(FeeTier({minAmount: 0, feeRate: _feeRate}));
    }
    
    /**
     * @dev 创建拍卖
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
        
        // 检查 NFT 所有权
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        
        // 转移 NFT 到合约
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        
        uint256 auctionId = _auctionIdCounter++;
        
        auctions[auctionId] = AuctionInfo({
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
            auctions[auctionId].startTime,
            auctions[auctionId].endTime,
            minBidUSD
        );
        
        return auctionId;
    }
    
    /**
     * @dev 使用 ETH 出价
     */
    function placeBid(uint256 auctionId) external payable onlyActiveAuction(auctionId) nonReentrant {
        require(msg.value > 0, "Bid amount must be greater than 0");
        
        IAuction.AuctionInfo storage auction = auctions[auctionId];
        require(auction.paymentToken == address(0), "This auction accepts tokens, not ETH");
        
        // 计算 USD 价值
        uint256 usdValue = ethPriceFeed.getETHAmountInUSD(msg.value);
        require(usdValue >= auction.minBid, "Bid too low");
        
        // 检查是否超过当前最高出价
        if (bids[auctionId].length > 0) {
            IAuction.Bid memory currentHighest = bids[auctionId][highestBidIndex[auctionId]];
            uint256 currentHighestUSD = currentHighest.isETH
                ? ethPriceFeed.getETHAmountInUSD(currentHighest.amount)
                : tokenPriceFeeds[auction.paymentToken].getTokenAmountInUSD(
                    currentHighest.amount
                );
            
            require(usdValue > currentHighestUSD, "Bid must be higher than current highest");
            
            // 退还之前的最高出价
            if (currentHighest.isETH) {
                payable(currentHighest.bidder).transfer(currentHighest.amount);
            } else {
                IERC20(auction.paymentToken).safeTransfer(currentHighest.bidder, currentHighest.amount);
            }
        }
        
        // 记录新出价
        bids[auctionId].push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            isETH: true
        }));
        
        highestBidIndex[auctionId] = bids[auctionId].length - 1;
        
        emit BidPlaced(auctionId, msg.sender, msg.value, true);
    }
    
    /**
     * @dev 使用 ERC20 代币出价
     */
    function placeBidWithToken(uint256 auctionId, uint256 amount) external onlyActiveAuction(auctionId) nonReentrant {
        require(amount > 0, "Bid amount must be greater than 0");
        
        IAuction.AuctionInfo storage auction = auctions[auctionId];
        require(auction.paymentToken != address(0), "This auction accepts ETH, not tokens");
        require(tokenPriceFeeds[auction.paymentToken] != AggregatorV3Interface(address(0)), "Price feed not set");
        
        // 转移代币
        IERC20(auction.paymentToken).safeTransferFrom(msg.sender, address(this), amount);
        
        // 获取代币精度并验证必须为 18
        uint8 decimals = IERC20Metadata(auction.paymentToken).decimals();
        require(decimals == 18, "Token decimals must be 18");
        
        // 计算 USD 价值
        uint256 usdValue = tokenPriceFeeds[auction.paymentToken].getTokenAmountInUSD(amount);
        require(usdValue >= auction.minBid, "Bid too low");
        
        // 检查是否超过当前最高出价
        if (bids[auctionId].length > 0) {
            IAuction.Bid memory currentHighest = bids[auctionId][highestBidIndex[auctionId]];
            uint256 currentHighestUSD;
            
            if (currentHighest.isETH) {
                currentHighestUSD = ethPriceFeed.getETHAmountInUSD(currentHighest.amount);
            } else {
                uint8 currentDecimals = IERC20Metadata(auction.paymentToken).decimals();
                require(currentDecimals == 18, "Token decimals must be 18");
                currentHighestUSD = tokenPriceFeeds[auction.paymentToken].getTokenAmountInUSD(
                    currentHighest.amount
                );
            }
            
            require(usdValue > currentHighestUSD, "Bid must be higher than current highest");
            
            // 退还之前的最高出价
            if (currentHighest.isETH) {
                payable(currentHighest.bidder).transfer(currentHighest.amount);
            } else {
                IERC20(auction.paymentToken).safeTransfer(currentHighest.bidder, currentHighest.amount);
            }
        }
        
        // 记录新出价
        bids[auctionId].push(Bid({
            bidder: msg.sender,
            amount: amount,
            timestamp: block.timestamp,
            isETH: false
        }));
        
        highestBidIndex[auctionId] = bids[auctionId].length - 1;
        
        emit BidPlaced(auctionId, msg.sender, amount, false);
    }
    
    /**
     * @dev 结束拍卖
     */
    function endAuction(uint256 auctionId) external nonReentrant {
        IAuction.AuctionInfo storage auction = auctions[auctionId];
        require(auction.status == IAuction.AuctionStatus.Active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");

        auction.status = IAuction.AuctionStatus.Ended;
        
        if (bids[auctionId].length == 0) {
            // 没有出价，退还 NFT
            IERC721(auction.nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);
            emit AuctionEnded(auctionId, address(0), 0);
            return;
        }
        
        IAuction.Bid memory winningBid = bids[auctionId][highestBidIndex[auctionId]];
        
        // 转移 NFT 给获胜者
        IERC721(auction.nftContract).safeTransferFrom(address(this), winningBid.bidder, auction.tokenId);
        
        // 计算手续费
        uint256 fee = calculateFee(winningBid.amount, winningBid.isETH);
        uint256 sellerAmount = winningBid.amount - fee;
        
        // 转移资金给卖家和手续费接收者
        if (winningBid.isETH) {
            payable(auction.seller).transfer(sellerAmount);
            payable(feeRecipient).transfer(fee);
        } else {
            IERC20(auction.paymentToken).safeTransfer(auction.seller, sellerAmount);
            IERC20(auction.paymentToken).safeTransfer(feeRecipient, fee);
        }
        
        emit AuctionEnded(auctionId, winningBid.bidder, winningBid.amount);
    }
    
    /**
     * @dev 取消拍卖（仅卖家）
     */
    function cancelAuction(uint256 auctionId) external {
        IAuction.AuctionInfo storage auction = auctions[auctionId];
        require(auction.status == IAuction.AuctionStatus.Active, "Auction not active");
        require(auction.seller == msg.sender, "Not seller");
        require(bids[auctionId].length == 0, "Cannot cancel auction with bids");

        auction.status = IAuction.AuctionStatus.Cancelled;
        
        // 退还 NFT
        IERC721(auction.nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);
        
        emit AuctionCancelled(auctionId);
    }
    
    /**
     * @dev 获取拍卖信息
     */
    function getAuction(uint256 auctionId) external view returns (IAuction.AuctionInfo memory) {
        return auctions[auctionId];
    }
    
    /**
     * @dev 获取最高出价
     */
    function getHighestBid(uint256 auctionId) external view returns (IAuction.Bid memory) {
        if (bids[auctionId].length == 0) {
            return Bid({
                bidder: address(0),
                amount: 0,
                timestamp: 0,
                isETH: false
            });
        }
        return bids[auctionId][highestBidIndex[auctionId]];
    }
    
    /**
     * @dev 获取所有出价
     */
    function getAllBids(uint256 auctionId) external view returns (IAuction.Bid[] memory) {
        return bids[auctionId];
    }
    
    /**
     * @dev 设置代币价格预言机
     */
    function setTokenPriceFeed(address token, address priceFeed) external onlyOwner {
        require(token != address(0), "Invalid token");
        require(priceFeed != address(0), "Invalid price feed");
        tokenPriceFeeds[token] = AggregatorV3Interface(priceFeed);
    }
    
    /**
     * @dev 设置手续费率
     */
    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 1000, "Fee rate too high");
        feeRate = _feeRate;
    }
    
    /**
     * @dev 设置手续费接收者
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }
    
    /**
     * @dev 添加手续费层级
     */
    function addFeeTier(uint256 minAmount, uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 1000, "Fee rate too high");
        feeTiers.push(FeeTier({minAmount: minAmount, feeRate: _feeRate}));
    }
    
    /**
     * @dev 计算手续费（支持动态手续费）
     */
    function calculateFee(uint256 amount, bool isETH) internal view returns (uint256) {
        // 计算 USD 价值
        uint256 usdValue;
        if (isETH) {
            usdValue = ethPriceFeed.getETHAmountInUSD(amount);
        } else {
            // 需要知道代币地址，这里简化处理
            // 实际实现中需要传入代币地址
            usdValue = 0; // 简化处理
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
    
    /**
     * @dev 接收 ETH
     */
    receive() external payable {
        revert("Use placeBid() function");
    }
}