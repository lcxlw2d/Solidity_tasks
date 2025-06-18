// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Voting {
    // 候选人地址列表
    address[] public candidates = [
        address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4),
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    ];
    // 初始化时传入候选人地址列表
    // constructor(address[] memory _candidates) {
    //     for (uint i = 0; i < _candidates.length; i++) {
    //         candidates.push(_candidates[i]);
    //     }
    // }

    // 候选人得票数
    mapping (address => uint) public votes;

    // 用户给某个候选人投票
    function vote (address _candidate) external {
        votes[_candidate]+=1;
    }

    // 获取某个候选人投票
    function getVote(address _candidate) external view returns (uint amount) {
        return votes[_candidate];
    }

    // 获取每个候选人得票数
    struct CandidateInfo {
        address candidate;
        uint votes;
    }
    function getVotes() external view returns(CandidateInfo[] memory results) {
        // 遍历candidates列表
        CandidateInfo[] memory result = new CandidateInfo[](candidates.length);
        
        for (uint i = 0; i < candidates.length; i++) {
            // 取出候选人地址
            address candidate = candidates[i];
            
            uint votesAmount = votes[candidate];
    
            result[i].candidate = candidate;
            result[i].votes = votesAmount;
        }

        return result;
        
    }

    // 重置所有候选人得票数
    function resetVotes() external {
        for (uint i = 0; i < candidates.length; i++) {
            votes[candidates[i]]=0;
        }
    }
}