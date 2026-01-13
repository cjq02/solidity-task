// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface INFTMarketplace {
    function mint(address to, string memory tokenURI) external returns (uint256);
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function nextTokenId() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}