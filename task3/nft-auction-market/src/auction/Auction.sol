// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IAuction} from "../interface/IAuction.sol";
import {PriceConverter} from "./PriceConverter.sol";

/**
 * @title Auction
 * @dev NFT 拍卖合约基类，支持 ETH 和 ERC20 出价（UUPS 可升级版本）
 * @custom:security-contact security@example.com
 */
abstract contract Auction is
    Initializable,
    IAuction,
    IERC721Receiver,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    using PriceConverter for AggregatorV3Interface;

    // ========== 状态变量 ==========

    uint256 private _auctionIdCounter;
    mapping(uint256 => IAuction.AuctionInfo) private _auctions;
    mapping(uint256 => IAuction.Bid[]) private _bids;
    mapping(uint256 => uint256) private _highestBidIndex;
    mapping(address => uint256) private _pendingETHWithdrawals;
    mapping(address => mapping(address => uint256))
        private _pendingTokenWithdrawals;

    AggregatorV3Interface public ethPriceFeed;
    mapping(address => AggregatorV3Interface) public tokenPriceFeeds;
    uint256 public feeRate;
    address public feeRecipient;

    // ========== 修饰符 ==========

    modifier onlyActiveAuction(uint256 auctionId) {
        _checkActiveAuction(auctionId);
        _;
    }

    /// @notice 检查拍卖是否处于活跃状态
    function _checkActiveAuction(uint256 auctionId) private view {
        require(
            _auctions[auctionId].status == IAuction.AuctionStatus.Active,
            "Auction not active"
        );
        require(
            block.timestamp >= _auctions[auctionId].startTime,
            "Auction not started"
        );
        require(
            block.timestamp < _auctions[auctionId].endTime,
            "Auction ended"
        );
    }

    // ========== UUPS 升级 ==========

    /// @notice UUPS 升级授权函数（只有 owner 可以升级）
    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    // ========== 初始化 ==========

    /// @notice 初始化合约（替代 constructor）
    function initialize(
        address initialOwner,
        address _ethPriceFeed,
        address _feeRecipient,
        uint256 _feeRate
    ) public virtual initializer {
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

        // 钩子函数，允许子合约扩展初始化逻辑
        _initializeHook();
    }

    /// @notice 初始化钩子函数，子合约可以重写
    function _initializeHook() internal virtual {}

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
    ) external virtual returns (uint256) {
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
    function placeBid(
        uint256 auctionId
    ) external payable virtual onlyActiveAuction(auctionId) nonReentrant {
        require(msg.value > 0, "Bid amount must be greater than 0");

        AuctionInfo storage auction = _auctions[auctionId];
        require(
            auction.paymentToken == address(0),
            "This auction accepts tokens, not ETH"
        );

        uint256 usdValue = ethPriceFeed.getETHAmountInUSD(msg.value);
        require(usdValue >= auction.minBid, "Bid too low");

        if (_bids[auctionId].length > 0) {
            Bid memory currentHighest = _bids[auctionId][
                _highestBidIndex[auctionId]
            ];
            uint256 currentHighestUSD = ethPriceFeed.getETHAmountInUSD(
                currentHighest.amount
            );
            require(
                usdValue > currentHighestUSD,
                "Bid must be higher than current highest"
            );
            _pendingETHWithdrawals[currentHighest.bidder] += currentHighest
                .amount;
        }

        _bids[auctionId].push(
            Bid({
                bidder: msg.sender,
                amount: msg.value,
                timestamp: block.timestamp,
                isETH: true
            })
        );

        _highestBidIndex[auctionId] = _bids[auctionId].length - 1;

        emit BidPlaced(auctionId, msg.sender, msg.value, true);
    }

    /**
     * @notice 使用 ERC20 代币出价
     */
    function placeBidWithToken(
        uint256 auctionId,
        uint256 amount
    ) external virtual onlyActiveAuction(auctionId) nonReentrant {
        require(amount > 0, "Bid amount must be greater than 0");

        AuctionInfo storage auction = _auctions[auctionId];
        require(
            auction.paymentToken != address(0),
            "This auction accepts ETH, not tokens"
        );
        require(
            address(tokenPriceFeeds[auction.paymentToken]) != address(0),
            "Price feed not set"
        );

        uint8 decimals = IERC20Metadata(auction.paymentToken).decimals();
        require(decimals == 18, "Token decimals must be 18");

        uint256 usdValue = tokenPriceFeeds[auction.paymentToken]
            .getTokenAmountInUSD(amount);
        require(usdValue >= auction.minBid, "Bid too low");

        if (_bids[auctionId].length > 0) {
            Bid memory currentHighest = _bids[auctionId][
                _highestBidIndex[auctionId]
            ];
            uint256 currentHighestUSD = tokenPriceFeeds[auction.paymentToken]
                .getTokenAmountInUSD(currentHighest.amount);
            require(
                usdValue > currentHighestUSD,
                "Bid must be higher than current highest"
            );
            _pendingTokenWithdrawals[currentHighest.bidder][
                auction.paymentToken
            ] += currentHighest.amount;
        }

        _bids[auctionId].push(
            Bid({
                bidder: msg.sender,
                amount: amount,
                timestamp: block.timestamp,
                isETH: false
            })
        );

        _highestBidIndex[auctionId] = _bids[auctionId].length - 1;

        IERC20(auction.paymentToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit BidPlaced(auctionId, msg.sender, amount, false);
    }

    /**
     * @notice 结束拍卖
     */
    function endAuction(uint256 auctionId) external virtual nonReentrant {
        AuctionInfo storage auction = _auctions[auctionId];
        require(
            auction.status == IAuction.AuctionStatus.Active,
            "Auction not active"
        );
        require(block.timestamp >= auction.endTime, "Auction not ended");

        auction.status = IAuction.AuctionStatus.Ended;

        if (_bids[auctionId].length == 0) {
            IERC721(auction.nftContract).safeTransferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );
            emit AuctionEnded(auctionId, address(0), 0);
            return;
        }

        Bid memory winningBid = _bids[auctionId][_highestBidIndex[auctionId]];

        IERC721(auction.nftContract).safeTransferFrom(
            address(this),
            winningBid.bidder,
            auction.tokenId
        );

        // 使用 virtual 函数计算手续费，子合约可以重写
        uint256 fee = calculateFee(
            winningBid.amount,
            winningBid.isETH,
            auction.paymentToken
        );
        uint256 sellerAmount = winningBid.amount - fee;

        if (winningBid.isETH) {
            (bool success1, ) = payable(auction.seller).call{
                value: sellerAmount
            }("");
            require(success1, "ETH transfer to seller failed");
            (bool success2, ) = payable(feeRecipient).call{value: fee}("");
            require(success2, "ETH transfer to fee recipient failed");
        } else {
            IERC20(auction.paymentToken).safeTransfer(
                auction.seller,
                sellerAmount
            );
            IERC20(auction.paymentToken).safeTransfer(feeRecipient, fee);
        }

        emit AuctionEnded(auctionId, winningBid.bidder, winningBid.amount);
    }

    /**
     * @notice 取消拍卖（仅卖家）
     */
    function cancelAuction(uint256 auctionId) external virtual {
        AuctionInfo storage auction = _auctions[auctionId];
        require(
            auction.status == IAuction.AuctionStatus.Active,
            "Auction not active"
        );
        require(auction.seller == msg.sender, "Not seller");
        require(
            _bids[auctionId].length == 0,
            "Cannot cancel auction with bids"
        );

        auction.status = IAuction.AuctionStatus.Cancelled;

        IERC721(auction.nftContract).safeTransferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        emit AuctionCancelled(auctionId);
    }

    // ========== 查询函数 ==========

    /**
     * @notice 获取拍卖信息
     */
    function getAuction(
        uint256 auctionId
    ) external view virtual returns (IAuction.AuctionInfo memory) {
        return _auctions[auctionId];
    }

    /**
     * @notice 获取最高出价
     */
    function getHighestBid(
        uint256 auctionId
    ) external view virtual returns (IAuction.Bid memory) {
        if (_bids[auctionId].length == 0) {
            return
                Bid({
                    bidder: address(0),
                    amount: 0,
                    timestamp: 0,
                    isETH: false
                });
        }
        return _bids[auctionId][_highestBidIndex[auctionId]];
    }

    /**
     * @notice 获取所有出价
     */
    function getAllBids(
        uint256 auctionId
    ) external view virtual returns (IAuction.Bid[] memory) {
        return _bids[auctionId];
    }

    // ========== 管理函数 ==========

    /**
     * @notice 设置代币价格预言机
     */
    function setTokenPriceFeed(
        address token,
        address priceFeed
    ) external virtual onlyOwner {
        require(token != address(0), "Invalid token");
        require(priceFeed != address(0), "Invalid price feed");
        tokenPriceFeeds[token] = AggregatorV3Interface(priceFeed);
    }

    /**
     * @notice 设置手续费率
     */
    function setFeeRate(uint256 _feeRate) external virtual onlyOwner {
        require(_feeRate <= 1000, "Fee rate too high");
        feeRate = _feeRate;
    }

    /**
     * @notice 设置手续费接收者
     */
    function setFeeRecipient(address _feeRecipient) external virtual onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    // ========== 手续费计算（可被子合约重写） ==========

    /**
     * @notice 计算手续费（子合约可以重写此函数实现自定义逻辑）
     */
    function calculateFee(
        uint256 amount,
        bool isETH,
        address paymentToken
    ) public view virtual returns (uint256) {
        // V1 版本：简单的固定手续费率
        return (amount * feeRate) / 10000;
    }

    // ========== 提现函数 ==========

    /**
     * @notice 提取待退还的 ETH
     */
    function withdrawETH() external virtual nonReentrant {
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
    function withdrawToken(address token) external virtual nonReentrant {
        uint256 amount = _pendingTokenWithdrawals[msg.sender][token];
        require(amount > 0, "No tokens to withdraw");
        _pendingTokenWithdrawals[msg.sender][token] = 0;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, false);
    }

    /**
     * @notice 接收 ETH
     */
    receive() external payable virtual {
        revert("Use placeBid() function");
    }

    /**
     * @notice 实现 ERC721Receiver 接口，允许合约接收 NFT
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure virtual override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
