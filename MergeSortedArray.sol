// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract MergeSortedArray {
    function merge(uint[] memory arr1, uint[] memory arr2) public pure returns (uint[] memory) {
        uint resultLength = arr1.length + arr2.length;
        uint[] memory result = new uint[](resultLength);
        // 双指针合并
        uint i = 0;
        uint j = 0;
        uint k = 0;
        while (i < arr1.length && j < arr2.length) {
            if (arr1[i] <= arr2[j]) {
                result[k] = arr1[i];
                k++;
                i++;
            } else {
                result[k] = arr2[j];
                j++;
                k++;
            }
        }
        while (i < arr1.length) {
            result[k] = arr1[i];
            i++;
            k++;
        }
        while (j < arr2.length) {
            result[k] = arr2[j];
            j++;
            k++;
        }
    
        return result;
    }
}