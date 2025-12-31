# MyNFT 作业提交

---

## 📋 基础信息

| 项目 | 内容 |
|:------|:------|
| 网络 | Sepolia |
| 钱包地址 | `0x085f0145202298585e699371eb3CFb1441f65110` |

---

## 📝 合约信息

| 项目 | 内容 |
|:------|:------|
| 合约名 | `MyNFT` |
| 合约地址 | `0x547AC05c817FD027d90CE1eE81DB9cC75baaeaf7` |
| 部署交易 hash | `0xf913adc76eb2bb61f27b8b4348becf645f380013f34ede3a48b36ce6f7c95661` |

---

## ✨ 铸造信息

| 项目 | 内容 |
|:------|:------|
| mint 交易 hash | `0x5249a67c3df8b8487d72adaddfc6052809e469c2ba4be7c0fea9f68d0e946269` |
| tokenId | `2` |
| tokenURI | `ipfs://bafkreihybznhkvtoxyexjek3rlft5votyirqlbxr5n73kakbekollmjboe` |

---

## 🌐 IPFS 资源

| 项目 | 链接 |
|:------|------|
| metadata 网关 | https://ipfs.io/ipfs/bafkreihybznhkvtoxyexjek3rlft5votyirqlbxr5n73kakbekollmjboe |
| image IPFS | `ipfs://bafybeiekahbtpgfpzwai352l4kiygxrius2bti4v2ipd34jukatgj5ckii` |
| image 网关 | https://ipfs.io/ipfs/bafybeiekahbtpgfpzwai352l4kiygxrius2bti4v2ipd34jukatgj5ckii |

**metadata.json 原文：**

```json
{
    "name": "My First NFT",
    "description": "这是我的第1个NFT",
    "image": "ipfs://bafybeiekahbtpgfpzwai352l4kiygxrius2bti4v2ipd34jukatgj5ckii"
}
```

---

## 📸 展示结果

### 1️⃣ 部署合约

![部署合约](./img/deploy.png)

---

### 2️⃣ Etherscan 合约页

> ✅ 能看到合约地址与交易列表

![Etherscan 合约页](./img/contract.png)

---

### 3️⃣ Etherscan mint 交易详情

> ✅ 能看到状态 Success、To=合约地址、Input 里包含 tokenURI

![交易列表](./img/transaction.png)

![交易详情](./img/transaction_detail.jpeg)

---

### 4️⃣ Sepolia Blockscout 资产展示

> ✅ OpenSea 测试网已关闭，使用 Blockscout 替代，能看到图片 + 名称 + 描述

![资产展示](./img/sepolia_blockscout.jpeg)
