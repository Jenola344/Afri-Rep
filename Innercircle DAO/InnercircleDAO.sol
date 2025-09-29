// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IAfriRep.sol";

/**
 * @title InnerCircleDAO - Exclusive communities based on reputation
 * @dev DAO implementation for high-reputation user groups
 */
contract InnerCircleDAO is AccessControl {
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 amount;
        address recipient;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    IAfriRep public afriRep;
    
    uint256 public minReputationToCreate;
    uint256 public minReputationToJoin;
    uint256 public proposalCount;
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public members;
    address[] public memberList;
    
    uint256 public constant VOTING_DELAY = 1 days;
    uint256 public constant VOTING_PERIOD = 3 days;
    
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event ProposalCreated(uint256 proposalId, address proposer, string title);
    event VoteCast(address voter, uint256 proposalId, bool support);
    event ProposalExecuted(uint256 proposalId);
    
    constructor(
        address _afriRepAddress,
        uint256 _minReputationToCreate,
        uint256 _minReputationToJoin
    ) {
        afriRep = IAfriRep(_afriRepAddress);
        minReputationToCreate = _minReputationToCreate;
        minReputationToJoin = _minReputationToJoin;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _addMember(msg.sender);
    }
    
    function addMember(address _newMember) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addMember(_newMember);
    }
    
    function _addMember(address _newMember) internal {
        (, , uint256 reputation, , , ) = afriRep.getUserProfile(_newMember);
        require(reputation >= minReputationToJoin, "Reputation too low");
        
        members[_newMember] = true;
        memberList.push(_newMember);
        
        emit MemberAdded(_newMember);
    }
    
    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _amount,
        address _recipient
    ) external returns (uint256) {
        require(members[msg.sender], "Only members can create proposals");
        
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.amount = _amount;
        proposal.recipient = _recipient;
        proposal.voteStart = block.timestamp + VOTING_DELAY;
        proposal.voteEnd = proposal.voteStart + VOTING_PERIOD;
        
        emit ProposalCreated(proposalId, msg.sender, _title);
        return proposalId;
    }
    
    function castVote(uint256 _proposalId, bool _support) external {
        require(members[msg.sender], "Only members can vote");
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp >= proposal.voteStart, "Voting not started");
        require(block.timestamp <= proposal.voteEnd, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
        
        emit VoteCast(msg.sender, _proposalId, _support);
    }
    
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp > proposal.voteEnd, "Voting not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal rejected");
        
        proposal.executed = true;
        
        // Execute proposal logic (simplified)
        if (proposal.amount > 0 && proposal.recipient != address(0)) {
            // In real implementation, would transfer funds
            // payable(proposal.recipient).transfer(proposal.amount);
        }
        
        emit ProposalExecuted(_proposalId);
    }
}