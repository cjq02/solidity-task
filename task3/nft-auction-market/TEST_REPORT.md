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