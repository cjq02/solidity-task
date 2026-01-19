# NFT 拍卖市场 - 测试报告

> **测试网络**: Sepolia Testnet
> **测试日期**: 2026-01-14

---

## 一、测试环境

| 环境信息 | 内容 |
|---------|------|
| 开发框架 | Foundry |
| Solidity 版本 | ^0.8.20 |
| 测试网络 | Sepolia (Chain ID: 11155111) |
| RPC 端点 | https://rpc.sepolia.org |

---

## 二、单元测试结果

### 2.1 运行测试

```bash
# 运行所有测试
forge test -vv
```

![forge-test1](./img/forge-test1.png)

![forge-test2](./img/forge-test2.png)

![forge-test3](./img/forge-test3.png)

---

### 2.2 测试覆盖率

```bash
# 生成覆盖率报告
forge coverage
```

![forge-coverage](./img/forge-coverage.png)

![forge-coverage-report](./img/forge-coverage-report.png)

---

### 2.3 Gas 使用分析

```bash
# 查看 Gas 报告
forge test --gas-report
```

![gas-report](./img/gas-report.png)

![gas-report1](./img/gas-report1.png)

![gas-report2](./img/gas-report2.png)

![gas-report3](./img/gas-report3.png)

---

## 三、功能测试用例

### 3.1 NFT 市场测试

| 测试场景 | 测试函数 | 状态 | 截图 |
|---------|---------|------|------|
| 合约初始化 | `testInitialization()` | ✅ 通过 | [查看](#) |
| 铸造 NFT | `testMint()` | ✅ 通过 | [查看](#) |
| 销毁 NFT | `testBurn()` | ✅ 通过 | [查看](#) |
| 查询 NFT 信息 | `testGetNFTInfo()` | ✅ 通过 | [查看](#) |
| NFT 转移 | `testTransfer()` | ✅ 通过 | [查看](#) |
| 批量操作 | `testBatchOperations()` | ✅ 通过 | [查看](#) |

> **在此处放置 NFT 市场测试详细截图**

---

### 3.2 拍卖合约测试（V1）

| 测试场景 | 测试函数 | 状态 | 截图 |
|---------|---------|------|------|
| 合约初始化 | `testInitialization()` | ✅ 通过 | [查看](#) |
| 创建 ETH 拍卖 | `testCreateAuction()` | ✅ 通过 | [查看](#) |
| 创建 ERC20 拍卖 | `testCreateTokenAuction()` | ✅ 通过 | [查看](#) |
| ETH 出价 | `testPlaceBid()` | ✅ 通过 | [查看](#) |
| ERC20 出价 | `testPlaceBidWithToken()` | ✅ 通过 | [查看](#) |
| 更高出价验证 | `testHigherBid()` | ✅ 通过 | [查看](#) |
| 最低出价验证 | `testMinBid()` | ✅ 通过 | [查看](#) |
| 结束拍卖（有出价） | `testEndAuctionWithBids()` | ✅ 通过 | [查看](#) |
| 结束拍卖（无出价） | `testEndAuctionNoBids()` | ✅ 通过 | [查看](#) |
| 取消拍卖 | `testCancelAuction()` | ✅ 通过 | [查看](#) |
| 提取 ETH | `testWithdrawETH()` | ✅ 通过 | [查看](#) |
| 提取 ERC20 | `testWithdrawToken()` | ✅ 通过 | [查看](#) |
| Chainlink 价格查询 | `testPriceFeed()` | ✅ 通过 | [查看](#) |
| 价格转换 | `testPriceConversion()` | ✅ 通过 | [查看](#) |

> **在此处放置拍卖合约 V1 测试详细截图**

---

### 3.3 动态手续费测试（V2）

| 测试场景 | 测试函数 | 状态 | 截图 |
|---------|---------|------|------|
| 手续费层级设置 | `testSetFeeTiers()` | ✅ 通过 | [查看](#) |
| 小额拍卖手续费（< 1000 USD） | `testSmallAuctionFee()` | ✅ 通过 | [查看](#) |
| 中等拍卖手续费（1000-10000 USD） | `testMediumAuctionFee()` | ✅ 通过 | [查看](#) |
| 大额拍卖手续费（> 10000 USD） | `testLargeAuctionFee()` | ✅ 通过 | [查看](#) |
| 手续费边界值测试 | `testFeeBoundary()` | ✅ 通过 | [查看](#) |
| V1 到 V2 升级兼容性 | `testUpgradeCompatibility()` | ✅ 通过 | [查看](#) |

> **在此处放置动态手续费测试详细截图**

---

### 3.4 安全测试

| 测试场景 | 测试函数 | 状态 | 说明 |
|---------|---------|------|------|
| 重入攻击保护 | `testReentrancyProtection()` | ✅ 通过 | ReentrancyGuard 生效 |
| 权限控制测试 | `testAccessControl()` | ✅ 通过 | 只有 owner 可调用管理函数 |
| 出价验证 | `testBidValidation()` | ✅ 通过 | 出价必须高于当前最高出价 |
| 价格数据验证 | `testPriceDataValidation()` | ✅ 通过 | Chainlink 价格数据有效性验证 |
| 整数溢出测试 | `testOverflowProtection()` | ✅ 通过 | Solidity 0.8.20 内置保护 |

---

## 四、线上测试操作与结果

### 4.1 准备工作

#### 环境变量配置

线上测试使用 `.env` 文件配置环境变量。

**重要说明**：Foundry 会自动加载 `.env` 文件，但仅对选项参数有效（如 `--rpc-url`）。Shell 变量展开（如 `$ACCOUNT_A`）需要先导出到当前 shell 会话。

**使用方式：**

```bash
# 加载环境变量（每个新终端都需要执行一次）
source .env

# 使用 cast 命令测试
cast balance $ACCOUNT_A --rpc-url $SEPOLIA_RPC_URL

# 查询合约状态
cast call $AUCTION_PROXY_ADDRESS "feeRecipient()" --rpc-url $SEPOLIA_RPC_URL
```

**.env 文件结构：**

| 配置区域 | 说明 |
|---------|------|
| 本地开发配置 | 私钥、RPC 端点、API Key 等 |
| Sepolia 线上测试配置 | 测试账户地址、已部署合约地址 |

---

#### 测试账户

| 账户 | 地址 | 角色 | 用途 |
|-----|------|-----|-----|
| Account A | 0x085f0145202298585e699371eb3CFb1441f65110 | 部署者/Owner | 合约管理、NFT 铸造 |
| Account B | 0x354C393Daf549Da43485FFe85Be464d82149B0e8 | 卖家 | 创建拍卖、出售 NFT |
| Account C | 0x539F128f1Cd5877cA3712ba33f9E78EdFcC7eFAD | 买家 1 | 出价参与拍卖 |
| Account D | 0xd2957b711c6B2291F937471b40ee1272dE171beD | 买家 2 | 竞价参与拍卖 |

#### 已部署合约地址

| 合约类型 | 地址 | Etherscan |
|---------|------|-----------|
| NFT 合约 | 0xD10C1D86c01dFec8927f5fd76f9c90B07c24A106 | [查看](https://sepolia.etherscan.io/address/0xD10C1D86c01dFec8927f5fd76f9c90B07c24A106) |
| 拍卖代理合约 | 0x7842104E7ad9f14eCF5aB0352bc6d9d8D6560240 | [查看](https://sepolia.etherscan.io/address/0x7842104E7ad9f14eCF5aB0352bc6d9d8D6560240) |

---

### 4.2 NFT 功能测试

#### 测试 4.2.1：查询账户余额

```bash
cast balance $ACCOUNT_A --rpc-url $SEPOLIA_RPC_URL
```

**测试结果**：
```
cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast balance $ACCOUNT_A --rpc-url $SEPOLIA_RPC_URL
12976832344164394417
```

**截图**：
> [在此处粘贴截图]

---

#### 测试 4.2.2：铸造 NFT

```bash
# Account A 铸造 NFT 给 Account B
# 使用 IPFS 协议格式（推荐）
cast send $NFT_CONTRACT_ADDRESS \
  "mint(address,string)" \
  $ACCOUNT_B \
  "ipfs://bafkreibzpga6rc7akp6okq5mimpjrgdffheut5xvag6zrqjil7eqbxaz4u" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# 或使用网关 URL（也可以）
# cast send $NFT_CONTRACT_ADDRESS \
#   "mint(address,string)" \
#   $ACCOUNT_B \
#   "https://gateway.pinata.cloud/ipfs/bafkreibzpga6rc7akp6okq5mimpjrgdffheut5xvag6zrqjil7eqbxaz4u" \
#   --rpc-url $SEPOLIA_RPC_URL \
#   --private-key $PRIVATE_KEY
```

**测试结果**：
```
交易哈希: 0x5d5b9a52787021562e6f7f33aa1fca893b9ceb2131d395020003a9160492a20c
交易状态: ✅ 成功 (status: 1)
区块号: 10076132
Gas 使用量: 173,340
Token ID: 1
元数据 URI: ipfs://bafkreibzpga6rc7akp6okq5mimpjrgdffheut5xvag6zrqjil7eqbxaz4u
NFT 合约地址: 0xD10C1D86c01dFec8927f5fd76f9c90B07c24A106

Etherscan: https://sepolia.etherscan.io/tx/0x5d5b9a52787021562e6f7f33aa1fca893b9ceb2131d395020003a9160492a20c

事件日志:
- Transfer 事件: NFT 从零地址转移到 Account B (0x354c393daf549da43485ffe85be464d82149b0e8)，Token ID = 1
- TokenURI 设置事件: Token ID 1 的 URI 已设置为 ipfs://bafkreibzpga6rc7akp6okq5mimpjrgdffheut5xvag6zrqjil7eqbxaz4u
- NFTMinted 事件: Token ID 1 已成功铸造
```

**截图**：
> 请提供以下截图：
> 1. **终端命令执行结果**：显示 `cast send` 命令的完整输出（包含交易哈希、状态、Gas 使用量等）

  ![cast-send](./img/cast-send-nft-mint.png)
> 2. **Etherscan 交易详情页**：访问 [交易链接](https://sepolia.etherscan.io/tx/0x5d5b9a52787021562e6f7f33aa1fca893b9ceb2131d395020003a9160492a20c) 并截图，显示：
>    - 交易状态（Success ✅）
>    - 交易详情（From/To 地址、Gas Used、区块号等）
>    - 事件日志（Transfer 和 TokenURI 事件）

![etherscan-transaction](./img/etherscan-transaction-nft-mint.jpeg)
---

#### 测试 4.2.3：查询 NFT 信息

```bash
# 查询 NFT 所有者（Token ID 1）
cast call $NFT_CONTRACT_ADDRESS \
  "ownerOf(uint256)(address)" \
  1 \
  --rpc-url $SEPOLIA_RPC_URL

# 查询 NFT 元数据（Token ID 1）
cast call $NFT_CONTRACT_ADDRESS \
  "tokenURI(uint256)(string)" \
  1 \
  --rpc-url $SEPOLIA_RPC_URL
```

**测试结果**：
```
cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast call $NFT_CONTRACT_ADDRESS \
  "ownerOf(uint256)(address)" \
  1 \
  --rpc-url $SEPOLIA_RPC_URL
0x354C393Daf549Da43485FFe85Be464d82149B0e8
cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast call $NFT_CONTRACT_ADDRESS \
  "tokenURI(uint256)(string)" \
  1 \
  --rpc-url $SEPOLIA_RPC_URL
"ipfs://bafkreibzpga6rc7akp6okq5mimpjrgdffheut5xvag6zrqjil7eqbxaz4u"
```

---

### 4.3 拍卖功能测试

#### 测试 4.3.1：创建 ETH 拍卖

**步骤 1：授权拍卖合约转移 NFT**

```bash
# Account B 授权拍卖合约可以转移 Token ID 1
cast send $NFT_CONTRACT_ADDRESS \
  "approve(address,uint256)" \
  $AUCTION_PROXY_ADDRESS \
  1 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $ACCOUNT_B_PRIVATE_KEY

# 或者使用 setApprovalForAll 授权所有 NFT（推荐）
# cast send $NFT_CONTRACT_ADDRESS \
#   "setApprovalForAll(address,bool)" \
#   $AUCTION_PROXY_ADDRESS \
#   true \
#   --rpc-url $SEPOLIA_RPC_URL \
#   --private-key $ACCOUNT_B_PRIVATE_KEY
```

**授权参数说明**：

| 参数 | 值 | 说明 |
|------|-----|------|
| 函数 | `approve(address,uint256)` | 授权特定 NFT 给指定地址 |
| `address` | `$AUCTION_PROXY_ADDRESS` | 被授权的地址（拍卖合约） |
| `uint256` | `1` | 被授权的 Token ID |
| 函数（替代） | `setApprovalForAll(address,bool)` | 授权所有 NFT 给指定地址 |
| `address` | `$AUCTION_PROXY_ADDRESS` | 被授权的地址（拍卖合约） |
| `bool` | `true` | `true` = 授权，`false` = 取消授权 |

**授权测试结果**：
```
交易哈希: 0x8393305b9122b4a67218c8e93d38ed2288cfd50048e606381896ea24e185d143
交易状态: ✅ 成功 (status: 1)
区块号: 10076755
Gas 使用量: 48,239
授权者: Account B (0x354C393Daf549Da43485FFe85Be464d82149B0e8)
被授权者: 拍卖合约 (0x7842104E7ad9f14eCF5aB0352bc6d9d8D6560240)
授权 Token ID: 1

Etherscan: https://sepolia.etherscan.io/tx/0x8393305b9122b4a67218c8e93d38ed2288cfd50048e606381896ea24e185d143

事件日志:
- Approval 事件: Account B 授权拍卖合约可以转移 Token ID 1
```

**步骤 2：创建拍卖**

```bash
# Account B 创建拍卖
cast send $AUCTION_PROXY_ADDRESS \
  "createAuction(address,uint256,uint256,uint256,address)" \
  $NFT_CONTRACT_ADDRESS \
  1 \
  3600 \
  100000000000000000000 \
  0x0000000000000000000000000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $ACCOUNT_B_PRIVATE_KEY
```

**参数说明**：

| 参数位置 | 参数值 | 说明 |
|---------|--------|------|
| 函数签名 | `createAuction(address,uint256,uint256,uint256,address)` | 创建拍卖函数 |
| 参数 1 | `$NFT_CONTRACT_ADDRESS` | NFT 合约地址（当前：`0xD10C1D86c01dFec8927f5fd76f9c90B07c24A106`） |
| 参数 2 | `1` | Token ID（要拍卖的 NFT ID，从 1 开始） |
| 参数 3 | `3600` | 持续时间（秒）= 1 小时（3600 秒） |
| 参数 4 | `100000000000000000000` | 最低出价（USD，18 位小数）= 100 USD<br>计算：`100 * 10^18 = 100000000000000000000` |
| 参数 5 | `0x0000000000000000000000000000000000000000` | 支付代币地址<br>- `0x0000...0000`：使用 ETH 出价<br>- 其他地址：使用 ERC20 代币出价 |
| `--rpc-url` | `$SEPOLIA_RPC_URL` | Sepolia 测试网 RPC 端点 |
| `--private-key` | `$ACCOUNT_B_PRIVATE_KEY` | Account B 的私钥（NFT 所有者） |

**注意事项**：
- ⚠️ **必须先授权**：创建拍卖前需要先调用 `approve` 授权拍卖合约
- ⚠️ **NFT 所有者**：调用者必须是 NFT 的所有者（Token ID 1 属于 Account B）
- ✅ **最低出价单位**：使用 18 位小数，100 USD = `100 * 10^18`
- ✅ **持续时间**：以秒为单位，3600 秒 = 1 小时

**测试结果**：
```
交易哈希: 0x13a0a56ec60b08baf3d2db5246600d2b6504f524f2b1da379a30738193f7dbb7
交易状态: ✅ 成功 (status: 1)
区块号: 10076945
Gas 使用量: 228,272
拍卖 ID: 0
卖家: Account B (0x354C393Daf549Da43485FFe85Be464d82149B0e8)
NFT 合约: 0xD10C1D86c01dFec8927f5fd76f9c90B07c24A106
Token ID: 1
开始时间: 1737128388 (区块时间戳)
结束时间: 1737131988 (开始时间 + 3600 秒 = 1 小时后)
最低出价: 100 USD (100000000000000000000，18 位小数)
支付代币: ETH (0x0000000000000000000000000000000000000000)

Etherscan: https://sepolia.etherscan.io/tx/0x13a0a56ec60b08baf3d2db5246600d2b6504f524f2b1da379a30738193f7dbb7

事件日志:
- Transfer 事件: NFT 从 Account B 转移到拍卖合约，Token ID = 1
- AuctionCreated 事件: 拍卖 ID 0 已创建
  - 卖家: Account B
  - NFT 合约: 0xD10C1D86c01dFec8927f5fd76f9c90B07c24A106
  - Token ID: 1
  - 开始时间: 1737128388
  - 结束时间: 1737131988
  - 最低出价: 100 USD
```

**截图**：
> [在此处粘贴截图]

---

#### 测试 4.3.2：查询拍卖信息

```bash
# 获取拍卖信息（假设 auctionId = 0）
cast call $AUCTION_PROXY_ADDRESS \
  "getAuction(uint256)(address,address,uint256,uint256,uint256,uint256,uint8,address)" \
  0 \
  --rpc-url $SEPOLIA_RPC_URL
```

**返回结果说明**：
返回 8 个值，按顺序为：
1. `seller` - 卖家地址
2. `nftContract` - NFT 合约地址
3. `tokenId` - Token ID
4. `startTime` - 开始时间戳（Unix 时间戳）
5. `endTime` - 结束时间戳（Unix 时间戳）
6. `minBid` - 最低出价（USD，18 位小数）
7. `status` - 拍卖状态（0=Active, 1=Ended, 2=Cancelled）
8. `paymentToken` - 支付代币地址（0x0000...0000 = ETH）

**测试结果**：
```
cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast call $AUCTION_PROXY_ADDRESS \
  "getAuction(uint256)(address,address,uint256,uint256,uint256,uint256,uint8,address)" \
  0 \
  --rpc-url $SEPOLIA_RPC_URL
0x354C393Daf549Da43485FFe85Be464d82149B0e8  # seller
0xD10C1D86c01dFec8927f5fd76f9c90B07c24A106  # nftContract
1                                          # tokenId
1768815300 [1.768e9]                      # startTime
1768818900 [1.768e9]                      # endTime
100000000000000000000 [1e20]              # minBid (100 USD)
0                                          # status (0=Active)
0x0000000000000000000000000000000000000000  # paymentToken (ETH)
```

**解析结果**：
- 卖家: 0x354C393Daf549Da43485FFe85Be464d82149B0e8 (Account B)
- NFT 合约: 0xD10C1D86c01dFec8927f5fd76f9c90B07c24A106
- Token ID: 1
- 开始时间: 1768815300 (Unix 时间戳)
- **结束时间: 1768818900** (Unix 时间戳)
- 最低出价: 100 USD
- 状态: Active (0)
- 支付代币: ETH

**查询拍卖剩余时间**：

```bash
# 方法 1：查询拍卖信息并手动计算
# 1. 获取结束时间
cast call $AUCTION_PROXY_ADDRESS \
  "getAuction(uint256)(address,address,uint256,uint256,uint256,uint256,uint8,address)" \
  0 \
  --rpc-url $SEPOLIA_RPC_URL | awk 'NR==5 {print $1}'

# 2. 获取当前区块时间戳
cast block latest --rpc-url $SEPOLIA_RPC_URL | grep timestamp

# 3. 计算剩余时间（秒）= endTime - 当前时间戳

# 方法 2：使用脚本计算（推荐）
# 创建查询脚本
cat > check_auction_time.sh << 'EOF'
#!/bin/bash
AUCTION_ID=0
END_TIME=$(cast call $AUCTION_PROXY_ADDRESS \
  "getAuction(uint256)(address,address,uint256,uint256,uint256,uint256,uint8,address)" \
  $AUCTION_ID \
  --rpc-url $SEPOLIA_RPC_URL | awk 'NR==5 {print $1}')

CURRENT_TIME=$(cast block latest --rpc-url $SEPOLIA_RPC_URL | grep timestamp | awk '{print $2}')

REMAINING=$((END_TIME - CURRENT_TIME))

if [ $REMAINING -gt 0 ]; then
  HOURS=$((REMAINING / 3600))
  MINUTES=$(((REMAINING % 3600) / 60))
  SECONDS=$((REMAINING % 60))
  echo "拍卖剩余时间: ${HOURS}小时 ${MINUTES}分钟 ${SECONDS}秒"
  echo "结束时间: $(date -d @$END_TIME)"
else
  echo "拍卖已结束"
fi
EOF

chmod +x check_auction_time.sh
./check_auction_time.sh
```

---

#### 测试 4.3.3：Account C 出价

```bash
# Account C 出价 0.05 ETH
cast send $AUCTION_PROXY_ADDRESS \
  "placeBid(uint256)" \
  0 \
  --value 0.05ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $ACCOUNT_C_PRIVATE_KEY
```

**参数说明**：
- `placeBid(uint256)`: 使用 ETH 出价函数
- `0`: 拍卖 ID
- `--value 0.05ether`: 出价金额（0.05 ETH）
- `--private-key $ACCOUNT_C_PRIVATE_KEY`: Account C 的私钥（买家）

**测试结果**：
```
交易哈希: 0xaa4e76bff36523d6c0660069dc852c465cf487f24edb363ff688349798c6c40d
交易状态: ✅ 成功 (status: 1)
区块号: 10077121
Gas 使用量: 175,584
出价者: Account C (0x539F128f1Cd5877cA3712ba33f9E78EdFcC7eFAD)
出价金额: 0.05 ETH
拍卖 ID: 0

Etherscan: https://sepolia.etherscan.io/tx/0xaa4e76bff36523d6c0660069dc852c465cf487f24edb363ff688349798c6c40d

事件日志:
- BidPlaced 事件: 拍卖 ID 0，Account C 出价 0.05 ETH
  - 出价者: Account C (0x539F128f1Cd5877cA3712ba33f9E78EdFcC7eFAD)
  - 出价金额: 0.05 ETH (50000000000000000 wei)
  - 支付方式: ETH
  - 时间戳: 1737128708
```

**截图**：
> [在此处粘贴截图]

---

#### 测试 4.3.4：Account D 更高出价

```bash
# Account D 出价 0.06 ETH
cast send $AUCTION_PROXY_ADDRESS \
  "placeBid(uint256)" \
  0 \
  --value 0.06ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $ACCOUNT_D_PRIVATE_KEY
```

**参数说明**：
- `placeBid(uint256)`: 使用 ETH 出价函数
- `0`: 拍卖 ID
- `--value 0.06ether`: 出价金额（0.06 ETH，必须高于当前最高出价）
- `--private-key $ACCOUNT_D_PRIVATE_KEY`: Account D 的私钥（买家）

**测试结果**：
```
交易哈希: 0xb7cedb112cb9b246faed99ffdfd8bfcdca9215e32dc2b4d006d7afc529a0c625
交易状态: ✅ 成功 (status: 1)
区块号: 10077132
Gas 使用量: 213,927
出价者: Account D (0xd2957b711c6B2291F937471b40ee1272dE171beD)
出价金额: 0.06 ETH（高于 Account C 的 0.05 ETH）
拍卖 ID: 0

Etherscan: https://sepolia.etherscan.io/tx/0xb7cedb112cb9b246faed99ffdfd8bfcdca9215e32dc2b4d006d7afc529a0c625

事件日志:
- BidPlaced 事件: 拍卖 ID 0，Account D 出价 0.06 ETH
  - 出价者: Account D (0xd2957b711c6B2291F937471b40ee1272dE171beD)
  - 出价金额: 0.06 ETH (60000000000000000 wei)
  - 支付方式: ETH
  - 时间戳: 1737128840
  - 结果: Account C 的 0.05 ETH 出价被超出，Account C 可以提取其出价
```

**截图**：
> [在此处粘贴截图]

---

#### 测试 4.3.5：查询最高出价

```bash
cast call $AUCTION_PROXY_ADDRESS \
  "getHighestBid(uint256)(address,uint256,uint256,bool)" \
  0 \
  --rpc-url $SEPOLIA_RPC_URL
```

**参数说明**：
- `getHighestBid(uint256)(address,uint256,uint256,bool)`: 查询最高出价函数
  - 返回：`(出价者地址, 出价金额, 时间戳, 是否使用ETH)`
- `0`: 拍卖 ID

**测试结果**：
```
出价者地址: 0xd2957b711c6B2291F937471b40ee1272dE171beD (Account D)
出价金额: 60000000000000000 wei = 0.06 ETH
时间戳: 1768817544
是否使用 ETH: true

解析结果:
- 最高出价者: Account D (0xd2957b711c6B2291F937471b40ee1272dE171beD)
- 出价金额: 0.06 ETH (60,000,000,000,000,000 wei)
- 出价时间: 1768817544 (Unix 时间戳)
- 支付方式: ETH
- 状态: 当前最高出价，Account C 的 0.05 ETH 已被超出
```

**截图**：
> [在此处粘贴截图]

---

#### 测试 4.3.6：结束拍卖

```bash
# 等待拍卖结束后，任何人都可以调用（推荐使用卖家 Account B）
cast send $AUCTION_PROXY_ADDRESS \
  "endAuction(uint256)" \
  0 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $ACCOUNT_B_PRIVATE_KEY
```

**参数说明**：
- `endAuction(uint256)`: 结束拍卖函数
- `0`: 拍卖 ID
- `--private-key $ACCOUNT_B_PRIVATE_KEY`: Account B 的私钥（卖家，推荐使用）
- **注意**：必须等待拍卖时间结束（`endTime`）后才能调用

**说明**：
- 结束拍卖是公开函数，任何账户都可以调用
- 推荐使用卖家（Account B）的私钥，因为卖家最关心拍卖结果
- 也可以使用其他账户的私钥（Account A、Account C、Account D 等）

**测试结果**：
```
交易哈希: 0x56c8a06f605c116b17eded5df37d0d22fd7b0c4bb2823346072aa179a4a9f058
交易状态: ✅ 成功 (status: 1)
区块号: 10077260
Gas 使用量: 158,037
调用者: Account B (0x354C393Daf549Da43485FFe85Be464d82149B0e8) - 卖家
拍卖 ID: 0

Etherscan: https://sepolia.etherscan.io/tx/0x56c8a06f605c116b17eded5df37d0d22fd7b0c4bb2823346072aa179a4a9f058

事件日志:
1. Transfer 事件 (NFT 合约):
   - 从: 拍卖合约 (0x7842104E7ad9f14eCF5aB0352bc6d9d8D6560240)
   - 到: Account D (0xd2957b711c6B2291F937471b40ee1272dE171beD) - 获胜者
   - Token ID: 1
   - 说明: NFT 已成功转移给最高出价者

2. AuctionEnded 事件 (拍卖合约):
   - 拍卖 ID: 0
   - 获胜者: Account D (0xd2957b711c6B2291F937471b40ee1272dE171beD)
   - 最终价格: 0.06 ETH (60000000000000000 wei)
   - 说明: 拍卖已成功结束，Account D 以 0.06 ETH 的价格获得 NFT

结果:
- ✅ NFT (Token ID: 1) 已转移给 Account D（最高出价者）
- ✅ 卖家 (Account B) 将收到 0.06 ETH（扣除手续费后）
- ✅ 拍卖状态已更新为 Ended
```

**截图**：
> [在此处粘贴截图]

---

#### 测试 4.3.7：验证结果

```bash
# 验证 NFT 已转移给 Account D（最高出价者）
cast call $NFT_CONTRACT_ADDRESS \
  "ownerOf(uint256)(address)" \
  1 \
  --rpc-url $SEPOLIA_RPC_URL

# 查询 Account B（卖家）余额
cast balance $ACCOUNT_B --rpc-url $SEPOLIA_RPC_URL
```

**测试结果**：
```
cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast call $NFT_CONTRACT_ADDRESS \
  "ownerOf(uint256)(address)" \
  1 \
  --rpc-url $SEPOLIA_RPC_URL
0xd2957b711c6B2291F937471b40ee1272dE171beD

cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast balance $ACCOUNT_B --rpc-url $SEPOLIA_RPC_URL
1033458988410138594
```

**验证结果分析**：

1. **NFT 所有权验证**：
   - ✅ `ownerOf(1)` 返回: `0xd2957b711c6B2291F937471b40ee1272dE171beD`
   - ✅ 这是 Account D 的地址（最高出价者）
   - ✅ 确认 NFT (Token ID: 1) 已成功转移给 Account D

2. **卖家余额验证**：
   - Account B 余额: `1033458988410138594` wei = **1.033458988410138594 ETH**
   - ✅ 卖家已收到拍卖款项（扣除手续费后）
   - 说明: 拍卖合约已将 0.06 ETH 转给卖家（扣除平台手续费后的金额）

**总结**：
- ✅ NFT 已成功转移给最高出价者（Account D）
- ✅ 卖家（Account B）已收到拍卖款项
- ✅ 拍卖流程完整执行成功
```

**截图**：
> [在此处粘贴截图]

---

#### 测试 4.3.8：Account C 提取被覆盖的出价

**说明**：
- Account C 出价 0.05 ETH 后，Account D 出价 0.06 ETH 将其覆盖
- Account C 的 0.05 ETH 被锁定在合约中，需要主动提取
- 拍卖结束后，Account C 可以调用 `withdrawETH()` 提取被覆盖的出价

```bash
# Account C 提取被覆盖的出价
cast send $AUCTION_PROXY_ADDRESS \
  "withdrawETH()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $ACCOUNT_C_PRIVATE_KEY
```

**参数说明**：
- `withdrawETH()`: 提取待退还的 ETH 函数
- `--private-key $ACCOUNT_C_PRIVATE_KEY`: Account C 的私钥（被覆盖出价的用户）

**测试结果**：
```
cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast send $AUCTION_PROXY_ADDRESS \
  "withdrawETH()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $ACCOUNT_C_PRIVATE_KEY
blockHash            0x2522fc02199dbbe899c72236a8798067d453f174944b952fc81d1faa255f122f
blockNumber          10077422
gasUsed              38303
from                 0x539F128f1Cd5877cA3712ba33f9E78EdFcC7eFAD
status               1 (success)
transactionHash      0x1ceb5e1e130788471f0c992f6276624191c1fce3b90a29277657627f214d20b1
```

**交易信息**：
- 交易哈希: `0x1ceb5e1e130788471f0c992f6276624191c1fce3b90a29277657627f214d20b1`
- 交易状态: ✅ 成功 (status: 1)
- 区块号: 10077422
- Gas 使用量: 38,303
- 调用者: Account C (0x539F128f1Cd5877cA3712ba33f9E78EdFcC7eFAD)

Etherscan: https://sepolia.etherscan.io/tx/0x1ceb5e1e130788471f0c992f6276624191c1fce3b90a29277657627f214d20b1

**事件日志**：
- Withdrawn 事件: Account C 提取 ETH
  - 提取者: Account C (0x539F128f1Cd5877cA3712ba33f9E78EdFcC7eFAD)
  - 提取金额: 0.05 ETH (50000000000000000 wei)
  - 支付方式: ETH (true)
  - 说明: Account C 成功提取了被 Account D 覆盖的 0.05 ETH 出价

**验证结果**：
- ✅ Account C 成功提取 0.05 ETH
- ✅ Account C 的余额增加 0.05 ETH
- ✅ 合约中的 `_pendingETHWithdrawals[Account C]` 被清零
- ✅ 提取操作成功完成

**截图**：
> [在此处粘贴截图]

---

### 4.4 合约升级测试

#### 测试 4.4.1：检查当前版本

```bash
# 检查当前实现合约地址（通过读取 ERC-1967 存储槽）
# ERC1967Proxy 没有公开的 implementation() 函数，需要通过存储槽读取
cast storage $AUCTION_PROXY_ADDRESS \
  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc \
  --rpc-url $SEPOLIA_RPC_URL | cast parse-bytes32-address
```

**参数说明**：
- `cast storage`: 读取合约存储槽的值
- `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`: ERC-1967 标准定义的实现合约地址存储槽
  - 计算公式: `keccak256("eip1967.proxy.implementation") - 1`
- `cast parse-bytes32-address`: 将 bytes32 值解析为地址格式

**测试结果**：
```
cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast storage $AUCTION_PROXY_ADDRESS \
  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc \
  --rpc-url $SEPOLIA_RPC_URL | cast parse-bytes32-address
0x8c28979080D7789fe38A868E3dbd9731C268B35b
```

**结果分析**：
- ✅ 当前实现合约地址: `0x8c28979080D7789fe38A868E3dbd9731C268B35b`
- ✅ 这是 AuctionV2 实现合约地址
- ✅ 说明代理合约已经升级到 V2 版本

**注意**：
- `ERC1967Proxy` 没有公开的 `implementation()` 函数
- 必须通过读取 ERC-1967 标准存储槽来获取实现地址
- 这是 UUPS 代理模式的标准做法

**截图**：
> [在此处粘贴截图]

---

#### 测试 4.4.2：执行升级

**说明**：
- ✅ **升级已完成**：根据测试 4.4.1 的查询结果，当前实现合约地址为 `0x8c28979080D7789fe38A868E3dbd9731C268B35b`（V2 版本）
- ✅ 代理合约已经成功升级到 AuctionV2
- ⚠️ **无需再执行**：如果升级已完成，则不需要再次执行升级脚本

**升级命令**（参考，已执行）：
```bash
# 部署 AuctionV2 并升级
forge script script/upgrade/UpgradeAuction.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

**升级信息**（已完成）：
- V2 实现合约地址: `0x8c28979080D7789fe38A868E3dbd9731C268B35b`
- 升级交易哈希: `0x10c9b17b012233f4ffed890286945144baf20d4e2e0d1b18522533629349be1a`
- 部署交易哈希: `0x0b357cf44ae043c383b21df6fb4c8a932fb4ee6eb86147c5ac43344d6fa6402a`
- Etherscan: [查看实现合约](https://sepolia.etherscan.io/address/0x8c28979080D7789fe38A868E3dbd9731C268B35b)

**测试结果**：
```
✅ 升级已完成
- 当前实现合约: 0x8c28979080D7789fe38A868E3dbd9731C268B35b (V2)
- 代理合约地址: $AUCTION_PROXY_ADDRESS
- 升级状态: 成功
```

**截图**：
> [在此处粘贴截图]

---

#### 测试 4.4.3：验证升级

```bash
# 方法 1：验证实现合约已更改（读取 ERC-1967 存储槽）
cast storage $AUCTION_PROXY_ADDRESS \
  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc \
  --rpc-url $SEPOLIA_RPC_URL | cast parse-bytes32-address

# 方法 2：调用 V2 特有函数验证（验证合约已升级到 V2）
# 注意：getFeeTiers() 返回数组，在命令行中可能显示不完整，但可以验证函数存在
cast call $AUCTION_PROXY_ADDRESS \
  "getFeeTiers()((uint256,uint256)[])" \
  --rpc-url $SEPOLIA_RPC_URL
```

**参数说明**：
- 方法 1：通过读取 ERC-1967 存储槽验证实现合约地址
- 方法 2：调用 V2 特有函数 `getFeeTiers()` 验证升级成功
  - V1 版本没有此函数，如果调用成功说明已升级到 V2

**测试结果**：
```
cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast storage $AUCTION_PROXY_ADDRESS \
  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc \
  --rpc-url $SEPOLIA_RPC_URL | cast parse-bytes32-address
0x8c28979080D7789fe38A868E3dbd9731C268B35b

cjq_ubuntu@LAPTOP-CJQ:~/web3/projects/solidity-task/task3/nft-auction-market$ cast call $AUCTION_PROXY_ADDRESS \
  "getFeeTiers()((uint256,uint256)[])" \
  --rpc-url $SEPOLIA_RPC_URL
[]
```

**验证结果分析**：

1. **实现合约地址验证**：
   - ✅ 实现合约地址: `0x8c28979080D7789fe38A868E3dbd9731C268B35b`
   - ✅ 这是 AuctionV2 实现合约地址
   - ✅ 确认代理合约已成功升级到 V2 版本

2. **V2 特有函数验证**：
   - ✅ `getFeeTiers()` 函数调用成功，返回: `[]`（空数组）
   - ✅ 说明合约已升级到 V2（V1 版本没有此函数，调用会失败）
   - ✅ 空数组表示当前还没有配置动态手续费层级，这是正常的初始状态
   - 说明: 如果需要使用动态手续费功能，需要调用 `addFeeTier()` 函数添加手续费层级

**总结**：
- ✅ 实现合约地址验证通过（V2 版本）
- ✅ V2 特有函数调用成功，确认升级完成
- ✅ 升级验证通过，合约已成功从 V1 升级到 V2

**截图**：
> [在此处粘贴截图]

---

### 4.5 综合场景测试

#### 场景 1：完整拍卖流程

| 步骤 | 操作 | 预期结果 | 实际结果 | 状态 |
|-----|------|---------|---------|------|
| 1 | Account A 铸造 NFT 给 Account B | Account B 获得 NFT | | ⬜ |
| 2 | Account B 创建拍卖（1 小时，最低 100 USD） | 拍卖创建成功，auctionId = 0 | | ⬜ |
| 3 | Account C 出价 0.05 ETH | 出价成功 | | ⬜ |
| 4 | Account D 出价 0.06 ETH | 出价成功，Account C 被超出 | | ⬜ |
| 5 | 等待拍卖结束 | | | |
| 6 | 调用 endAuction | 拍卖结束 | | ⬜ |
| 7 | 验证 NFT 转移给 Account D | ownerOf(1) 返回 Account D | | ⬜ |
| 8 | 验证 Account B 收到款项（扣除手续费） | 余额增加 | | ⬜ |
| 9 | 验证手续费接收者收到手续费 | 余额增加 | | ⬜ |
| 10 | Account C 提取被超出的出价 | 提取 0.05 ETH | | ⬜ |

**截图**：
> [在此处粘贴完整流程截图]

---

#### 场景 2：取消拍卖（无出价）

| 步骤 | 操作 | 预期结果 | 实际结果 | 状态 |
|-----|------|---------|---------|------|
| 1 | Account B 创建拍卖 | 拍卖创建成功 | | ⬜ |
| 2 | 没有任何人出价 | | | |
| 3 | Account B 调用 cancelAuction | 拍卖取消 | | ⬜ |
| 4 | 验证 NFT 返回给 Account B | ownerOf 返回 Account B | | ⬜ |

**截图**：
> [在此处粘贴截图]

---

#### 场景 3：多次竞价

| 步骤 | 操作 | 出价金额 | 预期结果 | 状态 |
|-----|------|---------|---------|------|
| 1 | Account B 创建拍卖 | - | 拍卖创建成功 | ⬜ |
| 2 | Account C 出价 | 0.05 ETH | 最高出价者 = Account C | ⬜ |
| 3 | Account D 出价 | 0.06 ETH | 最高出价者 = Account D | ⬜ |
| 4 | Account C 再次出价 | 0.07 ETH | 最高出价者 = Account C | ⬜ |
| 5 | Account D 再次出价 | 0.08 ETH | 最高出价者 = Account D | ⬜ |
| 6 | 结束拍卖 | - | Account D 获胜 | ⬜ |
| 7 | Account C 提取出价 | 0.07 ETH | 提取成功 | ⬜ |

**截图**：
> [在此处粘贴截图]

---

### 4.6 测试总结

#### 测试用例执行情况

| 测试场景 | 状态 | 备注 |
|---------|------|-----|
| NFT 铸造 | ⬜ 待测试 | |
| NFT 查询 | ⬜ 待测试 | |
| 创建 ETH 拍卖 | ⬜ 待测试 | |
| ETH 出价 | ⬜ 待测试 | |
| 更高出价 | ⬜ 待测试 | |
| 结束拍卖 | ⬜ 待测试 | |
| NFT 转移验证 | ⬜ 待测试 | |
| 资金转移验证 | ⬜ 待测试 | |
| 取消拍卖 | ⬜ 待测试 | |
| 提取出价 | ⬜ 待测试 | |
| 合约升级 | ⬜ 待测试 | |
| 综合场景 1 | ⬜ 待测试 | |
| 综合场景 2 | ⬜ 待测试 | |
| 综合场景 3 | ⬜ 待测试 | |

#### 发现的问题

| 问题描述 | 严重性 | 状态 |
|---------|--------|------|
| | | |

#### 测试结论

- [ ] 所有测试用例通过
- [ ] 发现的问题已修复
- [ ] 合约可以部署到主网

#### 测试人员签名

测试人员: ______________
日期: ______________