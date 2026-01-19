// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {NFTMarketplace} from "../../src/nft/NFTMarketplace.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

/**
 * @title NFTMarketplaceTest
 * @notice NFTMarketplace 合约功能测试
 */
contract NFTMarketplaceTest is Test {
    NFTMarketplace nft;

    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        // 部署 NFT 合约 (name, symbol, owner)
        nft = new NFTMarketplace("Test NFT", "TNFT", owner);
    }

    // ========== 测试：初始化 ==========

    function test_InitialState() public view {
        assertEq(nft.name(), "Test NFT");
        assertEq(nft.symbol(), "TNFT");
        assertEq(nft.owner(), owner);
        assertEq(nft.nextTokenId(), 1); // 从 1 开始
        assertEq(nft.totalSupply(), 0);
    }

    // ========== 测试：铸造 (mint) ==========

    function test_Mint() public {
        string memory uri = "ipfs://test-metadata";

        // 铸造 NFT
        uint256 tokenId = nft.mint(user1, uri);

        // 验证 tokenId
        assertEq(tokenId, 1); // 第一个 tokenId 是 1
        assertEq(nft.nextTokenId(), 2);
        assertEq(nft.totalSupply(), 1);

        // 验证所有权
        assertEq(nft.ownerOf(tokenId), user1);

        // 验证 tokenURI
        assertEq(nft.tokenURI(tokenId), uri);
    }

    function test_Mint_Multiple() public {
        // 铸造多个 NFT
        uint256 tokenId1 = nft.mint(user1, "ipfs://1");
        uint256 tokenId2 = nft.mint(user2, "ipfs://2");
        uint256 tokenId3 = nft.mint(user1, "ipfs://3");

        // 验证 tokenId 递增（从 1 开始）
        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
        assertEq(tokenId3, 3);

        // 验证总供应量
        assertEq(nft.totalSupply(), 3);
        assertEq(nft.nextTokenId(), 4);

        // 验证所有权
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user2);
        assertEq(nft.ownerOf(3), user1);

        // 验证 tokenURI
        assertEq(nft.tokenURI(1), "ipfs://1");
        assertEq(nft.tokenURI(2), "ipfs://2");
        assertEq(nft.tokenURI(3), "ipfs://3");
    }

    function test_MintFails_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.mint(user2, "ipfs://test");
    }

    // ========== 测试：销毁 (burn) ==========

    function test_Burn_ByOwner() public {
        // 先铸造一个 NFT
        uint256 tokenId = nft.mint(user1, "ipfs://test");

        // 用户销毁自己的 NFT
        vm.prank(user1);
        nft.burn(tokenId);

        // 验证 NFT 已销毁
        vm.expectRevert();
        nft.ownerOf(tokenId);

        // 注意：totalSupply 不会减少
        assertEq(nft.totalSupply(), 1);
    }

    function test_Burn_ByContractOwner() public {
        // 先铸造一个 NFT
        uint256 tokenId = nft.mint(user1, "ipfs://test");

        // 合约 owner 可以销毁任意 NFT
        nft.burn(tokenId);

        // 验证 NFT 已销毁
        vm.expectRevert();
        nft.ownerOf(tokenId);
    }

    function test_BurnFails_NotAuthorized() public {
        // 先铸造一个 NFT 给 user1
        uint256 tokenId = nft.mint(user1, "ipfs://test");

        // user2 尝试销毁 user1 的 NFT，应该失败
        vm.prank(user2);
        vm.expectRevert("Not authorized");
        nft.burn(tokenId);
    }

    function test_Burn_Multiple() public {
        // 铸造 3 个 NFT（tokenId: 1, 2, 3）
        nft.mint(user1, "ipfs://1");
        nft.mint(user1, "ipfs://2");
        nft.mint(user1, "ipfs://3");

        // 销毁中间的 NFT（tokenId 2）
        vm.prank(user1);
        nft.burn(2);

        // 验证其他 NFT 仍然存在
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(3), user1);

        // tokenId 2 已销毁
        vm.expectRevert();
        nft.ownerOf(2);
    }

    // ========== 测试：查询功能 ==========

    function test_NextTokenId() public {
        assertEq(nft.nextTokenId(), 1); // 从 1 开始

        nft.mint(user1, "ipfs://1");
        assertEq(nft.nextTokenId(), 2);

        nft.mint(user2, "ipfs://2");
        assertEq(nft.nextTokenId(), 3);

        // 销毁不影响 nextTokenId
        uint256 tokenId = nft.mint(user1, "ipfs://3");
        vm.prank(user1);
        nft.burn(tokenId);
        assertEq(nft.nextTokenId(), 4);
    }

    function test_TotalSupply() public {
        assertEq(nft.totalSupply(), 0);

        nft.mint(user1, "ipfs://1");
        assertEq(nft.totalSupply(), 1);

        nft.mint(user2, "ipfs://2");
        assertEq(nft.totalSupply(), 2);

        nft.mint(user1, "ipfs://3");
        assertEq(nft.totalSupply(), 3);

        // 销毁不影响 totalSupply
        uint256 tokenId = nft.mint(user1, "ipfs://4");
        vm.prank(user1);
        nft.burn(tokenId);
        assertEq(nft.totalSupply(), 4);
    }

    function test_TokenURI() public {
        string memory uri = "ipfs://QmTest123";
        uint256 tokenId = nft.mint(user1, uri);

        assertEq(nft.tokenURI(tokenId), uri);
    }

    function test_TokenURIFails_NotExist() public {
        vm.expectRevert();
        nft.tokenURI(999);
    }

    // ========== 测试：ERC721 标准功能 ==========

    function test_OwnerOf() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");

        assertEq(nft.ownerOf(tokenId), user1);
    }

    function test_TransferFrom() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");

        // user1 转账给 user2
        vm.prank(user1);
        nft.transferFrom(user1, user2, tokenId);

        assertEq(nft.ownerOf(tokenId), user2);
    }

    function test_SafeTransferFrom() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");

        // user1 安全转账给 user2
        vm.prank(user1);
        nft.safeTransferFrom(user1, user2, tokenId);

        assertEq(nft.ownerOf(tokenId), user2);
    }

    function test_TransferFromFails_NotOwner() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");

        // user2 尝试转账 user1 的 NFT，应该失败
        vm.prank(user2);
        vm.expectRevert();
        nft.transferFrom(user1, user2, tokenId);
    }

    function test_Approve() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");

        // user1 授权 user2 可以操作 tokenId
        vm.prank(user1);
        nft.approve(user2, tokenId);

        // user2 可以代表 user1 转账
        vm.prank(user2);
        nft.transferFrom(user1, user2, tokenId);

        assertEq(nft.ownerOf(tokenId), user2);
    }

    function test_SetApprovalForAll() public {
        uint256 tokenId1 = nft.mint(user1, "ipfs://1");
        uint256 tokenId2 = nft.mint(user1, "ipfs://2");

        // user1 授权 user2 可以操作所有 NFT
        vm.prank(user1);
        nft.setApprovalForAll(user2, true);

        // 验证授权状态
        assertEq(nft.isApprovedForAll(user1, user2), true);

        // user2 可以操作 user1 的所有 NFT
        vm.prank(user2);
        nft.transferFrom(user1, user2, tokenId1);

        assertEq(nft.ownerOf(tokenId1), user2);
        assertEq(nft.ownerOf(tokenId2), user1);
    }

    function test_BalanceOf() public {
        assertEq(nft.balanceOf(user1), 0);

        nft.mint(user1, "ipfs://1");
        assertEq(nft.balanceOf(user1), 1);

        nft.mint(user1, "ipfs://2");
        assertEq(nft.balanceOf(user1), 2);

        nft.mint(user2, "ipfs://3");
        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.balanceOf(user1), 2);
    }

    function test_SupportsInterface() public view {
        // ERC721 接口 ID
        bytes4 erc721Id = type(IERC721).interfaceId;

        assertTrue(nft.supportsInterface(erc721Id));
        assertTrue(nft.supportsInterface(0x80ac58cd)); // ERC721

        // 不支持的接口
        assertFalse(nft.supportsInterface(0xffffffff));
    }

    // ========== 测试：转账事件 ==========

    function test_Transfer_Event() public {
        uint256 tokenId = nft.mint(user1, "ipfs://test");

        vm.prank(user1);
        nft.transferFrom(user1, user2, tokenId);

        // 验证转账成功
        assertEq(nft.ownerOf(tokenId), user2);
    }
}
