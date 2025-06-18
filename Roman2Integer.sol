// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Roman2Integer {

    function romanToInt(string memory s) public pure returns (uint) {
        bytes memory roman = bytes(s);
        uint total = 0;
        uint prevValue = 0;
        
        // 从右向左遍历罗马数字
        for (uint i = roman.length; i > 0; i--) {
            bytes1 currentChar = roman[i-1];
            uint currentValue = getRomanValue(currentChar);
            
            // 如果当前值小于前一个值，则减去当前值(如IV=4)
            if (currentValue < prevValue) {
                total -= currentValue;
            } 
            // 否则加上当前值
            else {
                total += currentValue;
            }
            
            prevValue = currentValue;
        }
        
        return total;
    }
    
    // 获取罗马数字对应的值
    function getRomanValue(bytes1 romanChar) internal pure returns (uint) {
        if (romanChar == 'I') return 1;
        if (romanChar == 'V') return 5;
        if (romanChar == 'X') return 10;
        if (romanChar == 'L') return 50;
        if (romanChar == 'C') return 100;
        if (romanChar == 'D') return 500;
        if (romanChar == 'M') return 1000;
        return 0;
    }
}