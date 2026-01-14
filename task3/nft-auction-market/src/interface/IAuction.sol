// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAuction
 * @notice NFT 拍卖接口，定义拍卖合约的标准功能
 * @dev 支持使用 ETH 或 ERC20 代币进行出价
 */
interface IAuction {
    // 拍卖状态枚举
    enum AuctionStatus {
        Active, // 拍卖进行中
        Ended, // 拍卖已结束
        Cancelled // 拍卖已取消
    }

    /**
     * @notice 拍卖信息结构体
     * @param seller 卖家地址
     * @param nftContract NFT 合约地址
     * @param tokenId NFT token ID
     * @param startTime 拍卖开始时间戳
     * @param endTime 拍卖结束时间戳
     * @param minBid 最低出价（USD，18 位小数）
     * @param paymentToken 支付代币地址（address(0) 表示使用 ETH）
     * @param status 拍卖状态
     */
    struct AuctionInfo {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 minBid;
        address paymentToken;
        AuctionStatus status;
    }

    /**
     * @notice 出价信息结构体
     * @param bidder 出价者地址
     * @param amount 出价金额
     * @param timestamp 出价时间戳
     * @param isETH 是否为 ETH 出价（false 表示 ERC20 代币）
     */
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
        bool isETH;
    }

    /**
     * @notice 拍卖创建事件
     * @param auctionId 拍卖唯一标识符
     * @param seller 卖家地址
     * @param nftContract NFT 合约地址
     * @param tokenId NFT token ID
     * @param startTime 拍卖开始时间
     * @param endTime 拍卖结束时间
     * @param minBid 最低出价（USD）
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 minBid
    );

    /**
     * @notice 出价事件
     * @param auctionId 拍卖 ID
     * @param bidder 出价者地址
     * @param amount 出价金额
     * @param isETH 是否为 ETH 出价
     */
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        bool isETH
    );

    /**
     * @notice 拍卖结束事件
     * @param auctionId 拍卖 ID
     * @param winner 获胜者地址
     * @param finalPrice 最终成交价格（USD）
     */
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 finalPrice
    );

    /**
     * @notice 拍卖取消事件
     * @param auctionId 被取消的拍卖 ID
     */
    event AuctionCancelled(uint256 indexed auctionId);

    /**
     * @notice 提取事件
     * @param user 提取者地址
     * @param amount 提取金额
     * @param isETH 是否为 ETH（false 表示 ERC20 代币）
     */
    event Withdrawn(address indexed user, uint256 amount, bool isETH);

    /**
     * @notice 创建新的 NFT 拍卖
     * @dev 调用前需先授权合约操作 NFT
     * @param nftContract NFT 合约地址
     * @param tokenId 拍卖的 NFT token ID
     * @param duration 拍卖持续时间（秒）
     * @param minBidUSD 最低出价（USD，18 位小数）
     * @param paymentToken 支付代币地址（address(0) 表示接受 ETH）
     * @return auctionId 新创建的拍卖 ID
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 minBidUSD,
        address paymentToken
    ) external returns (uint256);

    /**
     * @notice 使用 ETH 出价
     * @dev 出价金额通过 msg.value 传递，需高于当前最高出价
     * @param auctionId 拍卖 ID
     */
    function placeBid(uint256 auctionId) external payable;

    /**
     * @notice 使用 ERC20 代币出价
     * @dev 调用前需先授权合约操作代币
     * @param auctionId 拍卖 ID
     * @param amount 出价金额
     */
    function placeBidWithToken(uint256 auctionId, uint256 amount) external;

    /**
     * @notice 结束拍卖并完成交易
     * @dev 只有拍卖结束后才能调用，NFT 转给获胜者，款项转给卖家
     * @param auctionId 拍卖 ID
     */
    function endAuction(uint256 auctionId) external;

    /**
     * @notice 取消拍卖
     * @dev 只有卖家可以取消，且只能取消没有出价的活跃拍卖
     * @param auctionId 拍卖 ID
     */
    function cancelAuction(uint256 auctionId) external;

    /**
     * @notice 获取拍卖信息
     * @param auctionId 拍卖 ID
     * @return auction 拍卖详细信息
     */
    function getAuction(
        uint256 auctionId
    ) external view returns (AuctionInfo memory);

    /**
     * @notice 获取当前最高出价
     * @param auctionId 拍卖 ID
     * @return bid 最高出价信息
     */
    function getHighestBid(
        uint256 auctionId
    ) external view returns (Bid memory);

    /**
     * @notice 提取待退还的 ETH
     * @dev 出价被覆盖后，用户需主动调用此函数提取资金
     */
    function withdrawETH() external;

    /**
     * @notice 提取待退还的 ERC20 代币
     * @param token 代币合约地址
     * @dev 出价被覆盖后，用户需主动调用此函数提取资金
     */
    function withdrawToken(address token) external;
}
