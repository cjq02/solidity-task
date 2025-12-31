// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * 作业2：在测试网上发行一个图文并茂的 NFT
 */

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyNFT is ERC721, ERC721URIStorage, Ownable {
    // TODO: 用于生成递增 tokenId
    uint256 private _tokenIdCounter;

    // 最大供应量
    uint256 public constant MAX_SUPPLY = 100;

    // TODO: 事件（可选但推荐）
    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        string tokenURI
    );

    // TODO: 构造函数：把 name 与 symbol 传给 ERC721
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {}

    /**
     * 允许用户铸造NFT
     */
    function mintNFT(string memory uri) external returns (uint256 tokenId) {
        // 先检查
        require(_tokenIdCounter < MAX_SUPPLY, "Max supply reached");
        require(bytes(uri).length > 0, "Empty tokenURI");

        unchecked {
            // 递增计数器，初始值为0，第1件NFT为1
            _tokenIdCounter++;
        }
        tokenId = _tokenIdCounter;
        // 安全铸造NFT
        _safeMint(msg.sender, tokenId);
        // 设置元数据uri
        _setTokenURI(tokenId, uri);

        emit NFTMinted(msg.sender, tokenId, uri);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
