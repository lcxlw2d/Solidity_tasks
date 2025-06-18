// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract BinarySearch {
    function search(int256[] memory array, int256 item) public pure returns (uint256 index) {
        uint left = 0;
        uint right = array.length;

        while(left < right) {
            uint middle = left + (right - left) / 2;
            if (item == array[middle]) {
                return middle;
            }
            if (array[middle] > item) {
                right = middle;
            } else {
                left = middle + 1;
            }
        }

    }
}