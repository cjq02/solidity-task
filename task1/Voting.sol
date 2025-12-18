// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Candidate {
        string name;
        uint voteCount;
        bool exists;
    }
    // 候选人总数（自增 ID，下一个候选人的 ID = candidateCount++）
    uint candidateCount = 0;

    address public immutable OWNER;

    // 以candidateId为key
    mapping(uint => Candidate) public candidates;
    // 以candidateId为key，嵌套内以sender address为key
    mapping(uint => mapping(address => bool)) public hasVoted;

    event CandidateCreated(string name);
    event Voted(address indexed voter, uint candidateId);
    event VotesReset();

    constructor() {
        OWNER = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == OWNER, "Only Owner can call");
        _;
    }

    modifier candidateExists(uint candidateId) {
        require(candidates[candidateId].exists, "Candidate does not exist");
        _;
    }

    /**
     * 创建候选人
     */
    function createCandidate(
        Candidate calldata newCandidate
    ) external onlyOwner {
        // 验证参数
        require(bytes(newCandidate.name).length > 0, "Name cannot be empty");
        // 创建候选人
        uint candidateId = candidateCount++;

        candidates[candidateId] = Candidate({
            name: newCandidate.name,
            voteCount: 0,
            exists: true
        });
        emit CandidateCreated(newCandidate.name);
    }

    // TODO: 实现投票函数
    function vote(uint candidateId) public candidateExists(candidateId) {
        // 增加候选人得票数
        candidates[candidateId].voteCount++;
        // TODO: 如果是新候选人，添加到数组
        hasVoted[candidateId][msg.sender] = true;
        // TODO: 触发事件
        emit Voted(msg.sender, candidateId);
    }

    // TODO: 实现查询得票数函数
    function getVotes(
        uint candidateId
    ) public view candidateExists(candidateId) returns (uint) {
        // TODO: 返回候选人得票数
        return candidates[candidateId].voteCount;
    }

    // 实现重置所有得票数函数
    function resetVotes() public {
        // 遍历所有候选人，重置得票数为0
        for (uint candidateId = 0; candidateId < candidateCount; ) {
            candidates[candidateId].voteCount = 0;
            // 怎么清空hasVoted
            // hasVoted[candidateId]
            unchecked {
                candidateId++;
            }
        }

        // 触发事件
        emit VotesReset();
    }
}
