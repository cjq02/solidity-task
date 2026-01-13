// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title NFTMarketplace
 * @dev NFT 市场合约，基于 ERC721 标准
 */
contract NFTMarketplace is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // 映射：tokenId => tokenURI
    mapping(uint256 => string) private _tokenURIs;

    // 事件
    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        string tokenURI
    );
    event NFTBurned(uint256 indexed tokenId);

    /**
     * @dev 构造函数
     * @param name NFT 名称
     * @param symbol NFT 符号
     * @param initialOwner 初始所有者
     */
    constructor(
        string memory name,
        string memory symbol,
        address initialOwner
    ) ERC721(name, symbol) Ownable(initialOwner) {}

    /**
     * @dev 铸造 NFT
     * @param to 接收者地址
     * @param tokenURI NFT 元数据 URI
     * @return tokenId 新铸造的 token ID
     */
    function mint(
        address to,
        string memory tokenURI
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit NFTMinted(to, tokenId, tokenURI);

        return tokenId;
    }

    /**
     * @dev 销毁 NFT
     * @param tokenId 要销毁的 token ID
     */
    function burn(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender || msg.sender == owner(),
            "Not authorized"
        );
        _burn(tokenId);
        emit NFTBurned(tokenId);
    }

    /**
     * @dev 获取当前 token ID 计数
     * @return 下一个可用的 token ID
     */
    function nextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev 获取总供应量
     * @return 已铸造的 NFT 总数
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
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

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }
}
