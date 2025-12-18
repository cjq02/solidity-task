// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IntegerToRoman {
    /**
     * @dev 整数转罗马数字
     * @param num 整数，范围 [1, 3999]
     * @return 罗马数字字符串
     */
    function intToRoman(uint num) public pure returns (string memory) {
        uint[13] memory values = [uint(1000), 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
        string[13] memory symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
        
        bytes memory result;
        
        for (uint i = 0; i < 13; ) {
            while (num >= values[i]) {
                result = abi.encodePacked(result, symbols[i]);
                num -= values[i];
            }
            unchecked {
                i++;
            }
        }
        
        return string(result);
    }
}

