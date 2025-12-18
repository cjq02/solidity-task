// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BinarySearch {
    /**
     * @dev 二分查找
     * @param nums 有序数组，比如[1,2,3,4,6,7,8,9]
     * @param target 目标值
     * @return 目标值的索引，不存在返回 type(uint).max
     */
    function search(
        uint[] memory nums,
        uint target
    ) public pure returns (uint) {
        // 处理空数组
        require(nums.length > 0, "Empty array");

        // 初始化左右指针
        uint left = 0;
        uint right = nums.length - 1;

        // TODO: 循环查找
        while (left <= right) {
            // 计算中间位置
            uint middle = left + (right - left) / 2;

            // 如果中间值等于目标值，返回索引
            if (nums[middle] == target) {
                return middle;
            }
            // 如果中间值小于目标值，左指针右移
            else if (nums[middle] < target) {
                left = middle + 1;
            }
            // 如果中间值大于目标值，右指针左移
            else {
                if (middle == 0) {
                    break;
                }
                right = middle - 1;
            }
        }

        // 未找到返回 type(uint).max
        return type(uint).max;
    }
}
