# NFT 拍卖市场

> 使用 Foundry 框架开发的 NFT 拍卖市场，支持 ETH 和 ERC20 代币出价，集成 Chainlink 预言机，使用 UUPS 代理模式实现合约升级。

---

## 项目简介

本项目是一个功能完整的 NFT 拍卖市场智能合约系统，实现了以下核心功能：

- **NFT 管理**: 基于 ERC721 标准的 NFT 铸造、销毁和转移
- **拍卖功能**: 支持创建拍卖、ETH/ERC20 出价、结束拍卖、取消拍卖
- **价格预言机**: 集成 Chainlink 价格预言机，实现实时 ETH 和 ERC20 到美元的价格转换
- **合约升级**: 使用 UUPS 代理模式，支持合约无缝升级（V1 固定手续费 → V2 动态手续费）
- **动态手续费**: 根据拍卖金额自动调整手续费率（额外挑战功能）

---

## 技术栈

| 技术 | 说明 |
|-----|------|
| **开发框架** | Foundry |
| **Solidity 版本** | ^0.8.20 |
| **NFT 标准** | ERC721 (OpenZeppelin) |
| **代理模式** | UUPS (ERC1967Proxy) |
| **价格预言机** | Chainlink Price Feeds |
| **测试网络** | Sepolia Testnet |

---

## 项目结构

```
nft-auction-market/
├── src/                           # 智能合约源代码
│   ├── interface/                 # 接口定义
│   │   ├── IAuction.sol          # 拍卖合约接口
│   │   └── INFTMarketplace.sol   # NFT 市场接口
│   ├── nft/                      # NFT 合约
│   │   └── NFTMarketplace.sol    # NFT 市场合约（ERC721）
│   └── auction/                  # 拍卖合约
│       ├── Auction.sol           # 拍卖合约基类（抽象）
│       ├── AuctionV1.sol         # V1 版本（固定手续费 2.5%）
│       ├── AuctionV2.sol         # V2 版本（动态手续费）
│       └── PriceConverter.sol    # Chainlink 价格转换库
│
├── test/                         # 测试文件
│   ├── nft/
│   │   └── NFTMarketplace.t.sol  # NFT 市场测试
│   └── auction/
│       ├── Auction.t.sol         # 拍卖合约基本功能测试
│       └── AuctionV2.t.sol       # 动态手续费测试
│
├── script/                       # 部署脚本
│   ├── deploy/
│   │   └── Deploy.s.sol          # 部署 AuctionV1 代理合约
│   ├── upgrade/
│   │   └── Upgrade.s.sol         # 升级到 V2 脚本
│   └── Interact.s.sol            # 合约交互脚本
│
├── doc/                          # 文档
│   ├── 提交内容指南.md
│   ├── 测试网部署指南.md
│   ├── 线上测试操作指南.md
│   └── 提交内容模板.md
│
├── foundry.toml                  # Foundry 配置文件
├── README.md                     # 项目文档
└── TEST_REPORT.md                # 测试报告
```

---

## 核心合约说明

### 1. NFTMarketplace.sol

NFT 市场合约，基于 ERC721 标准。

**主要功能**:
- `mint(address to, string memory uri)` - 铸造 NFT（仅 owner）
- `burn(uint256 tokenId)` - 销毁 NFT
- `tokenURI(uint256 tokenId)` - 查询 NFT 元数据
- `totalSupply()` - 查询总供应量
- `nextTokenId()` - 获取下一个可用的 token ID

---

### 2. Auction.sol (抽象基类)

拍卖合约的抽象基类，定义了核心拍卖逻辑。

**继承关系**:
```
Initializable
    ↓
OwnableUpgradeable
    ↓
ReentrancyGuardUpgradeable
    ↓
UUPSUpgradeable
    ↓
Auction (抽象)
    ↓
AuctionV1 / AuctionV2
```

**核心功能**:
| 函数 | 说明 |
|-----|------|
| `createAuction(...)` | 创建拍卖，支持指定 NFT、持续时间、最低出价、支付代币 |
| `placeBid(uint256)` | 使用 ETH 出价 |
| `placeBidWithToken(uint256, uint256)` | 使用 ERC20 代币出价 |
| `endAuction(uint256)` | 结束拍卖，NFT 转移给出价最高者 |
| `cancelAuction(uint256)` | 取消拍卖（仅卖家，无出价时） |
| `withdrawETH()` | 提取被超出的 ETH 出价 |
| `withdrawToken(address)` | 提取被超出的 ERC20 出价 |

**查询函数**:
| 函数 | 说明 |
|-----|------|
| `getAuction(uint256)` | 获取拍卖完整信息 |
| `getHighestBid(uint256)` | 获取当前最高出价 |
| `getAllBids(uint256)` | 获取所有出价记录 |

**管理函数** (仅 owner):
| 函数 | 说明 |
|-----|------|
| `setTokenPriceFeed(address, address)` | 设置 ERC20 代币的价格预言机 |
| `setFeeRate(uint256)` | 设置手续费率（V1） |
| `setFeeTier(uint256, uint256, uint256)` | 设置动态手续费层级（V2） |
| `setFeeRecipient(address)` | 设置手续费接收者 |
| `upgradeTo(address)` | 升级合约实现 |

---

### 3. AuctionV1.sol

拍卖合约 V1 版本，实现**固定手续费率 2.5%**。

**特点**:
- 简单固定的手续费机制
- 适合初始版本使用
- 可升级到 V2

---

### 4. AuctionV2.sol

拍卖合约 V2 版本，实现**动态手续费层级**（额外挑战功能）。

**手续费层级**:

| 拍卖成交金额 | 手续费率 |
|-------------|---------|
| < 1,000 USD | **3%** |
| 1,000 - 10,000 USD | **2.5%** |
| > 10,000 USD | **2%** |

**特点**:
- 根据成交金额自动调整费率
- 大额交易享受更低手续费
- 可配置的层级系统

---

### 5. PriceConverter.sol

Chainlink 价格转换工具库。

**功能**:
- `getETHPrice()` - 获取 ETH/USD 价格
- `getETHAmountInUSD(uint256)` - 将 ETH 金额转换为 USD
- `getTokenAmountInUSD(uint256)` - 将 ERC20 金额转换为 USD
- `compareBids(...)` - 比较两个出价的 USD 价值

---

## Chainlink 价格预言机集成

### Sepolia 测试网地址

| 代币对 | 合约地址 | Decimals |
|-------|---------|----------|
| ETH/USD | `0x694AA1769357215DE4FAC081bf1f309aDC325306` | 8 |
| BTC/USD | `0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43` | 8 |
| USDC/USD | `0xA2F78ab2355Fe2Cd48370b735A90A59a274934F8` | 8 |

> 更多地址: https://docs.chain.link/data-feeds/price-feeds/addresses

---

## 部署步骤

### 环境准备

1. **安装 Foundry**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **克隆项目**
   ```bash
   git clone https://github.com/cjq02/solidity-task.git
   cd solidity-task/task3/nft-auction-market
   ```

3. **安装依赖**
   ```bash
   forge install
   ```

---

### 编译合约

```bash
# 编译所有合约
forge build

# 查看编译输出
ls -la out/
```

> **在此处放置编译成功截图**

**编译输出示例**:
```
Compiler run successful
```

---

### 运行测试

```bash
# 运行所有测试
forge test -vv

# 运行测试并显示 Gas 报告
forge test --gas-report

# 生成测试覆盖率报告
forge coverage
```

> **在此处放置测试通过截图**

**测试输出示例**:
```
Running 3 tests for test/NFTMarketplace.t.sol
[PASS] testInitialization() (gas: 285432)
[PASS] testMint() (gas: 156789)
[PASS] testBurn() (gas: 45123)
Test result: ok. 3 passed; 0 failed; finished
```

---

### 部署到 Sepolia 测试网

#### 1. 获取必要的配置信息

##### 1.1 获取 Infura RPC URL

1. 访问 https://infura.io/
2. 点击 **"Sign Up"** 注册账号
3. 登录后，点击 **"Create New Key"**
4. 选择 **"Web3 API"**
5. 创建一个新项目，名称如 "NFT Auction Market"
6. 在项目设置中，找到 **"Endpoints"** → **"Ethereum"**
7. 在网络下拉列表中选择 **"Sepolia"**
8. 复制 **HTTPS Endpoint**，格式如下：
   ```
   https://sepolia.infura.io/v3/YOUR_PROJECT_ID
   ```

> **在此处放置 Infura 获取 RPC URL 截图**

---

##### 1.2 获取 Etherscan API Key

1. 访问 https://etherscan.io/
2. 点击右上角 **"Sign In"** → **"Register"** 注册账号
3. 登录后，点击右上角头像 → **"API Keys"**
4. 滚动到 **"API Keys"** 部分
5. 点击 **"Add"** 添加新 API Key
6. 复制 **API Key Token**（是一串 32 位字符）

> **在此处放置 Etherscan 获取 API Key 截图**

---

##### 1.3 准备其他配置

| 配置项 | 说明 | 值 |
|-------|------|-----|
| `PRIVATE_KEY` | 部署钱包的私钥（不要包含 0x 前缀） | 从 MetaMask 导出 |
| `ETH_PRICE_FEED` | Chainlink ETH/USD 价格预言机地址（Sepolia） | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| `FEE_RECIPIENT` | 手续费接收地址 | 你的钱包地址 |

---

#### 2. 配置环境变量

在项目根目录创建 `.env` 文件，配置以下环境变量：

| 环境变量 | 说明 | 来源 |
|---------|------|------|
| `PRIVATE_KEY` | 部署钱包的私钥（不要包含 0x 前缀） | 从 MetaMask 导出 |
| `SEPOLIA_RPC_URL` | Infura Sepolia RPC 端点 | 从 Infura 获取（见上文） |
| `ETHERSCAN_API_KEY` | Etherscan API 密钥 | 从 Etherscan 获取（见上文） |
| `ETH_PRICE_FEED` | Chainlink ETH/USD 价格预言机地址 | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| `FEE_RECIPIENT` | 手续费接收地址 | 你的钱包地址 |

> **在此处放置 .env 文件配置截图**

---

#### 4. 部署 NFT 合约

```bash
# 加载环境变量并部署
source .env

forge script script/deploy/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --delay 15
```

> **在此处放置 NFT 合约部署截图**

**部署信息**:

| 项目 | 值 |
|-----|---|
| 合约地址 | `0x...` |
| 交易哈希 | `0x...` |
| Etherscan | [查看合约](链接) |

**部署命令说明**:
- `--rpc-url`: RPC 端点
- `--broadcast`: 广播交易到区块链
- `--verify`: 在 Etherscan 上验证合约
- `--etherscan-api-key`: Etherscan API 密钥
- `--delay 15`: 每次交易之间延迟 15 秒

---

#### 5. 部署拍卖合约（V1）

```bash
# 部署 AuctionV1 代理合约
forge script script/deploy/Deploy.s.sol:DeployAuction \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --delay 15
```

> **在此处放置拍卖合约部署截图**

**部署信息**:

| 项目 | 值 |
|-----|---|
| 实现合约地址 | `0x...` |
| 代理合约地址 | `0x...` |
| 交易哈希 | `0x...` |
| Etherscan | [查看合约](链接) |

**部署参数**:

| 参数 | 值 |
|-----|---|
| 初始 Owner | `0x...` |
| ETH 价格预言机 | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| 手续费率 | 2.5% (250 basis points) |
| 手续费接收者 | `0x...` |

---

#### 6. 验证部署

使用 Cast 命令验证合约部署：

```bash
# 查询合约 owner
cast call <PROXY_ADDRESS> "owner()(address)" --rpc-url $SEPOLIA_RPC_URL

# 查询手续费率
cast call <PROXY_ADDRESS> "feeRate()(uint256)" --rpc-url $SEPOLIA_RPC_URL

# 查询 ETH 价格预言机
cast call <PROXY_ADDRESS> "ethPriceFeed()(address)" --rpc-url $SEPOLIA_RPC_URL
```

> **在此处放置合约验证截图**

---

### 合约升级（V1 → V2）

#### 1. 准备升级

```bash
# 记录当前实现合约地址
cast call <PROXY_ADDRESS> "implementation()(address)" --rpc-url $SEPOLIA_RPC_URL
```

#### 2. 执行升级

```bash
# 升级到 AuctionV2
forge script script/upgrade/Upgrade.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --delay 15
```

> **在此处放置合约升级截图**

**升级信息**:

| 项目 | 值 |
|-----|---|
| V2 实现合约地址 | `0x...` |
| 交易哈希 | `0x...` |
| Etherscan | [查看合约](链接) |

#### 3. 验证升级

```bash
# 验证实现合约已更改
cast call <PROXY_ADDRESS> "implementation()(address)" --rpc-url $SEPOLIA_RPC_URL

# 调用 V2 特有函数验证
cast call <PROXY_ADDRESS> "getFeeTierCount()(uint256)" --rpc-url $SEPOLIA_RPC_URL
```

> **在此处放置升级验证截图**

---

### 部署检查清单

- [ ] Foundry 安装成功
- [ ] 项目依赖安装完成
- [ ] 合约编译成功（`forge build`）
- [ ] 测试全部通过（`forge test -vv`）
- [ ] Infura RPC URL 获取成功
- [ ] Etherscan API Key 获取成功
- [ ] .env 文件配置正确
- [ ] 测试账户有足够 ETH（至少 0.5 ETH）
- [ ] NFT 合约部署成功
- [ ] 拍卖合约部署成功
- [ ] 合约在 Etherscan 上验证通过
- [ ] 合约功能验证正常
- [ ] 合约升级成功（V1 → V2）

---

## 使用示例

### 创建 NFT 拍卖

```solidity
// 创建一个 7 天拍卖，最低出价 100 USD，接受 ETH 出价
auction.createAuction(
    nftContract,      // NFT 合约地址
    tokenId,          // NFT ID
    7 days,           // 拍卖持续时间
    100 USD,          // 最低出价（美元）
    address(0)        // address(0) 表示接受 ETH
);
```

### 出价

```solidity
// 使用 ETH 出价
auction.placeBid{value: 0.05 ether}(auctionId);

// 使用 ERC20 代币出价（需先授权）
auction.placeBidWithToken(auctionId, 500 * 10^18);
```

### 结束拍卖

```solidity
// 拍卖时间结束后，任何人都可以调用
auction.endAuction(auctionId);
```

---

## 已部署合约信息

### Sepolia 测试网

| 合约 | 地址 | Etherscan |
|-----|------|-----------|
| NFTMarketplace | `0x...` | [查看](链接) |
| Auction Proxy | `0x...` | [查看](链接) |
| Auction Implementation (V1) | `0x...` | [查看](链接) |
| Auction Implementation (V2) | `0x...` | [查看](链接) |

---

## 文档

| 文档 | 路径 | 说明 |
|-----|------|------|
| 提交内容指南 | [doc/提交内容指南.md](doc/提交内容指南.md) | 作业提交清单和要求 |
| 测试网部署指南 | [doc/测试网部署指南.md](doc/测试网部署指南.md) | 详细的部署步骤说明 |
| 线上测试操作指南 | [doc/线上测试操作指南.md](doc/线上测试操作指南.md) | 合约功能测试步骤 |
| 测试报告 | [TEST_REPORT.md](TEST_REPORT.md) | 测试结果和覆盖率 |

---

## 项目亮点

1. **完整的 UUPS 代理模式**
   - 支持合约无缝升级
   - 升级后数据完整保留
   - 演示了 V1 到 V2 的平滑升级

2. **灵活的支付方式**
   - 同时支持 ETH 和 ERC20 代币
   - 可配置任意 ERC20 代币
   - Chainlink 实时价格转换

3. **动态手续费系统**（额外挑战）
   - 根据拍卖金额自动调整手续费率
   - 大额交易享受更低费率
   - 可扩展的层级配置

4. **安全机制**
   - 重入攻击保护（ReentrancyGuard）
   - 权限控制（Ownable）
   - 价格数据验证
   - 出价验证机制

---

## License

MIT
