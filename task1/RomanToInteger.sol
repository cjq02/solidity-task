// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RomanToInteger {
    // 罗马字符对应的数值
    mapping(bytes1 => uint) public symbolValues;

    constructor() {
        symbolValues["I"] = 1;
        symbolValues["V"] = 5;
        symbolValues["X"] = 10;
        symbolValues["L"] = 50;
        symbolValues["C"] = 100;
        symbolValues["D"] = 500;
        symbolValues["M"] = 1000;
    }

    /**
     * @dev 罗马数字转整数
     * @param str 罗马数字字符串，如 "MCMXCIV"
     * @return 对应的整数，如 1994
     */
    function romanToInt(string memory str) public view returns (uint) {
        // 将string转换为bytes
        bytes memory strBytes = bytes(str);
        uint strLength = strBytes.length;
        uint result = 0;

        // 遍历字符串
        for (uint i = 0; i < strLength; ) {
            uint current = symbolValues[strBytes[i]];
            // 如果当前字符值 < 下一个字符值，则减去当前值（如IV=4, IX=9）
            uint next = (i + 1 < strLength) ? symbolValues[strBytes[i + 1]] : 0;

            if (current < next) {
                result -= current;
            } else {
                result += current;
            }

            // 否则加上当前值
            unchecked {
                i++;
            }
        }

        // 返回结果
        return result;
    }
}
