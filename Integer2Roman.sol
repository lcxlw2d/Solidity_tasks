// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Integer2Roman {
    function intToRoman(uint num) public pure returns (string memory) {
        require(num > 0 && num < 4000, "Number out of range (1-3999)");
        
        // 定义罗马数字符号和对应的值
        string[13] memory romanSymbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
        uint[13] memory romanValues = [uint(1000), 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
        
        bytes memory result = new bytes(32);
        uint ptr = 0;
        
        for (uint i = 0; i < romanValues.length; i++) {
            while (num >= romanValues[i]) {
                num -= romanValues[i];
                bytes memory symbol = bytes(romanSymbols[i]);
                
                // 将符号添加到结果中
                for (uint j = 0; j < symbol.length; j++) {
                    result[ptr++] = symbol[j];
                }
            }
        }
        
        // 调整结果长度并转换为string
        bytes memory trimmedResult = new bytes(ptr);
        for (uint k = 0; k < ptr; k++) {
            trimmedResult[k] = result[k];
        }
        
        return string(trimmedResult);
    }
}