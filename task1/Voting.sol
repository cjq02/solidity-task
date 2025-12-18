// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Candidate {
        string name;
        uint voteCount;
        bool exists;
    }

    uint private constant FIRST_CANDIDATE_ID = 1;

    // 候选人总数（自增 ID，下一个候选人的 ID = candidateCount++）
    uint candidateCount = FIRST_CANDIDATE_ID;

    address public immutable OWNER;

    // 以candidateId为key
    mapping(uint => Candidate) public candidates;
    // 以sender address为key，候选人Id为值
    mapping(address => uint) public hasVoted;
    // 已投过票的用户
    address[] public votedUserList;

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
     * @dev 创建候选人
     * @param newCandidate 候选人信息
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

    /**
     * @dev 投票给指定候选人
     * @param candidateId 候选人ID
     */
    function vote(uint candidateId) public candidateExists(candidateId) {
        require(hasVoted[msg.sender] == 0, "You have already voted");
        // 增加候选人得票数
        candidates[candidateId].voteCount++;
        // 如果是新候选人，添加到数组
        hasVoted[msg.sender] = candidateId;
        votedUserList.push(msg.sender);
        // 触发事件
        emit Voted(msg.sender, candidateId);
    }

    /**
     * @dev 查询候选人得票数
     * @param candidateId 候选人ID
     * @return 得票数
     */
    function getVotes(
        uint candidateId
    ) public view candidateExists(candidateId) returns (uint) {
        // 返回候选人得票数
        return candidates[candidateId].voteCount;
    }

    /**
     * @dev 重置所有候选人得票数和投票记录
     */
    function resetVotes() public onlyOwner {
        // 重置得票数
        for (uint candidateId = FIRST_CANDIDATE_ID; candidateId < candidateCount; ) {
            candidates[candidateId].voteCount = 0;
            unchecked {
                candidateId++;
            }
        }

        uint votedUserListLength = votedUserList.length;
        // 重置投票记录
        for (uint i = 0; i < votedUserListLength; i++) {
            hasVoted[votedUserList[i]] = 0;
        }
        delete votedUserList;

        // 触发事件
        emit VotesReset();
    }
}
