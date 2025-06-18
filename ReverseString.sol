// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract ReverseString {
    function reverse(string memory str) public pure returns (string memory) {
        bytes memory bytesStr = bytes(str);
        uint length = bytesStr.length;

        if (length <= 1) {
            return str;
        }

        bytes memory reversedBytes = new bytes(length);

        for (uint i = 0; i < length; ++i) {
            uint indexToReversed = length - 1 - i;
            reversedBytes[indexToReversed] = bytesStr[i];
        }

        return string(reversedBytes);
    }
}