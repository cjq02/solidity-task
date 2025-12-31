// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * 讨饭合约 BeggingContract
 */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BeggingContract is Ownable {
    // 捐赠记录集合
    mapping(address => uint256) private _donations;

    // TODO(可选): Donation 事件
    event Donation(address indexed donor, uint256 amount, uint256 totalDonated);
    event Withdraw(address indexed owner, uint256 amount);

    constructor() Ownable(msg.sender) {}

    /**
     * 允许用户向合约发送 ETH，并记录捐赠信息
     */
    function donate() external payable {
        // 检查金额
        require(msg.value > 0, "Donation amount must be greater than 0");
        // 用户捐赠金额累加
        _donations[msg.sender] += msg.value;
        // 触发捐赠事件
        emit Donation(msg.sender, msg.value, _donations[msg.sender]);
    }

    /**
     * 合约所有者可提取合约全部余额
     */
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        // 检查合约余额
        require(balance > 0, "No balance");
        // 把合约余额转给所有者
        payable(owner()).transfer(balance);
        // 触发取款事件
        emit Withdraw(msg.sender, balance);
    }

    /**
     * 返回某个地址累计捐赠金额
     */
    function getDonation(address donor) external view returns (uint256) {
        return _donations[donor];
    }
}
