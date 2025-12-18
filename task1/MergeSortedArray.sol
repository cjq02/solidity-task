// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MergeSortedArray {
    /**
     * @dev 合并两个有序数组
     * @param nums1 数字1
     * @param nums2 数字2
     * @return 合并后的有序数组
     */
    function merge(
        uint[] memory nums1,
        uint[] memory nums2
    ) public pure returns (uint[] memory) {
        // 获取两个数组的长度
        uint len1 = nums1.length;
        uint len2 = nums2.length;

        // 创建结果数组，长度为两数组长度之和
        uint[] memory result = new uint[](len1 + len2);

        uint i = 0;
        uint j = 0;
        uint k = 0;

        while (i < len1 && j < len2) {
            if (nums1[i] <= nums2[j]) {
                result[k] = nums1[i];
                i++;
            } else {
                result[k] = nums2[j];
                j++;
            }
            k++;
        }

        while (i < len1) {
            result[k] = nums1[i];
            i++;
            k++;
        }

        while (j < len2) {
            result[k] = nums2[j];
            j++;
            k++;
        }

        return result;
    }
}
