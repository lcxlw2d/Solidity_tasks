// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PriceFeedMock is AggregatorV3Interface {
    uint8 public decimals = 8;
    int256 private price;
    uint80 private roundId = 1;

    function setPrice(int256 _price) public {
        price = _price;
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (roundId, price, 0, 0, roundId);
    }

    // 其他接口函数省略，测试中不需要
    function description() external pure returns (string memory) {
        return "";
    }

    function version() external pure returns (uint256) {
        return 0;
    }

    function getRoundData(
        uint80
    ) external pure returns (uint80, int256, uint256, uint256, uint80) {
        return (0, 0, 0, 0, 0);
    }
}
