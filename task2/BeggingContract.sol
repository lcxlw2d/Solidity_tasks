// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract BeggingContract {
    address public owner;
    // 记录捐赠者和捐赠金额
    mapping (address => uint256) donations;
    uint256 public totalDonatedAmount;

    event Donation(address indexed donator, uint256 amount, uint256 timestamp);
    uint256 public donationStartTime;
    uint256 public donationEndTime;

    struct TopDonor {
        address donor;
        uint256 amount;
    }

    TopDonor[] public top3Donors;

    constructor(uint256 _durationHours) {
        owner = msg.sender;
        donationStartTime = block.timestamp;
        donationEndTime = donationStartTime + _durationHours * 1 hours;
    }

    // 给合约捐赠
    function donate() public payable {
        require(block.timestamp > donationStartTime, "Donation is not started");
        require(block.timestamp > donationStartTime && block.timestamp < donationEndTime, "Donation period is over");
        require(msg.value > 0, "Donation amount must be greater than 0");
        address donator = msg.sender;
        donations[donator] += msg.value;
        totalDonatedAmount += msg.value;
        emit Donation(donator, msg.value, block.timestamp);
         // 更新捐赠排行榜
        updateTopDonors(msg.sender, donations[msg.sender]);
    }
    // 更新前三名
    function updateTopDonors(address donor, uint256 amount) private {
        for(uint i = 0; i < 3; i++) {
            if (top3Donors[i].donor == donor) {
                top3Donors[i].amount += amount;
                _sortTopDonors();
                return;
            }
            if (amount > top3Donors[2].amount) {
                top3Donors[2] = TopDonor(donor, amount);
                _sortTopDonors();
            }
        }
    }
    // 排序前三名
    function _sortTopDonors() internal {
        for(uint i = 0; i < 2; i++) {
            for(uint j = 0; j < 2; j++) {
                if (top3Donors[j].amount < top3Donors[j+1].amount) {
                    TopDonor memory temp = top3Donors[j];
                    top3Donors[j] = top3Donors[j+1];
                    top3Donors[j+1] = temp;
                }
            }
        }
    }
    // 查询某个地址的捐赠金额
    function getDonation(address donor) public view returns (uint256) {
        return donations[donor];
    }
    // 提款
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance>0, "Not enough funds to withdraw.");
        payable(owner).transfer(balance);
    }
    // 接收主动转账
    receive() external payable {
        donate();
    }
}