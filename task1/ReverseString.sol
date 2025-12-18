// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReverseString {
    /**
     * @dev 反转字符串
     * @param input 输入字符串，如 "abcde"
     * @return 反转后的字符串，如 "edcba"
     */
    function reverse(string memory input) public pure returns (string memory) {
        // 将string转换为bytes
        bytes memory inputBytes = bytes(input);
        // 获取长度
        uint inputLength = inputBytes.length;
        // 创建新的bytes数组存储结果
        bytes memory result = new bytes(inputLength);
        // 从后向前遍历，填充结果数组
        for (uint i = 0; i < inputLength; ) {
            result[i] = inputBytes[inputLength - i - 1];
            unchecked {
                i++;
            }
        }
        // 将bytes转换回string并返回
        return string(result);
    }
}
