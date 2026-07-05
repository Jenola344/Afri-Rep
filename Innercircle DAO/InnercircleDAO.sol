// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title IAfriRep — Minimal interface for reputation lookups.
 */
interface IAfriRep {
    function getUserProfile(address _user)
        external
        view
        returns (
            string memory name,
            string memory countryCode,
            uint256 reputationScore,
            bool isVerified,
            string memory profileImageHash,
            uint256 lastActivity
        );
}

/**
 * @title InnerCircleDAO — Reputation-Gated Community Governance
 * @author Afri Rep Contributors
 * @notice Allows high-reputation users to form exclusive communities (Inner
 *         Circles) with on-chain proposal voting and treasury management.
 *         Inspired by traditional African savings groups (Ajo, Stokvel, Iqub)
 *         combined with modern DAO governance.
 * @dev Membership requires a minimum reputation score from the AfriRep
 *      contract. Proposals have a 1-day voting delay and 3-day voting period.
 *      A quorum of 30% of members must participate for a proposal to be valid.
 *      Supports ETH treasury via `receive()`.
 */
contract InnerCircleDAO is AccessControl, ReentrancyGuard {
    // ──────────────────────────────────────────────
    //  Data Structures
    // ──────────────────────────────────────────────

    /// @notice Proposal states for lifecycle tracking.
    enum ProposalState {
        Pending,    // Created, waiting for voting to start
        Active,     // Voting is open
        Defeated,   // Voting ended, did not pass
        Succeeded,  // Voting ended, passed
        Executed,   // Successfully executed
        Cancelled   // Cancelled by proposer or admin
    }

    /// @notice On-chain governance proposal.
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 amount;          // ETH amount to transfer (0 if non-financial)
        address recipient;       // Recipient of funds (address(0) if non-financial)
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        bool cancelled;
        mapping(address => bool) hasVoted;
        mapping(address => address) delegations; // voter => delegate
    }

    // ──────────────────────────────────────────────
    //  State
    // ──────────────────────────────────────────────

    /// @notice Reference to the AfriRep reputation contract.
    IAfriRep public afriRep;

    /// @notice Minimum reputation required to create this DAO.
    uint256 public minReputationToCreate;

    /// @notice Minimum reputation required to join as a member.
    uint256 public minReputationToJoin;

    /// @notice Running count of proposals (used as proposal ID).
    uint256 public proposalCount;

    /// @notice Proposal ID → Proposal data.
    mapping(uint256 => Proposal) public proposals;

    /// @notice Address → membership status.
    mapping(address => bool) public members;

    /// @notice Ordered list of member addresses.
    address[] public memberList;

    /// @notice Address → delegate address for voting.
    mapping(address => address) public votingDelegates;

    /// @notice Delay between proposal creation and voting start.
    uint256 public constant VOTING_DELAY = 1 days;

    /// @notice Duration of the voting window.
    uint256 public constant VOTING_PERIOD = 3 days;

    /// @notice Quorum: minimum percentage of members that must vote (30%).
    uint256 public constant QUORUM_PERCENTAGE = 30;

    /// @notice Name of this Inner Circle.
    string public circleName;

    /// @notice Description of this Inner Circle.
    string public circleDescription;

    // ──────────────────────────────────────────────
    //  Events
    // ──────────────────────────────────────────────

    /// @notice Emitted when a new member joins the circle.
    event MemberAdded(address indexed member, uint256 reputation);

    /// @notice Emitted when a member is removed from the circle.
    event MemberRemoved(address indexed member, address indexed removedBy);

    /// @notice Emitted when a new proposal is created.
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 amount);

    /// @notice Emitted when a vote is cast.
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 weight);

    /// @notice Emitted when a proposal is executed.
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor, uint256 amount);

    /// @notice Emitted when a proposal is cancelled.
    event ProposalCancelled(uint256 indexed proposalId, address indexed canceller);

    /// @notice Emitted when a member delegates their voting power.
    event VoteDelegated(address indexed delegator, address indexed delegate);

    /// @notice Emitted when ETH is deposited to the treasury.
    event TreasuryDeposit(address indexed sender, uint256 amount);

    // ──────────────────────────────────────────────
    //  Errors
    // ──────────────────────────────────────────────

    error ReputationTooLow(uint256 required, uint256 actual);
    error AlreadyMember();
    error NotMember();
    error VotingNotStarted();
    error VotingEnded();
    error VotingNotEnded();
    error AlreadyVoted();
    error ProposalAlreadyExecuted();
    error ProposalNotPassed();
    error ProposalAlreadyCancelled();
    error NotProposer();
    error QuorumNotReached(uint256 required, uint256 actual);
    error TransferFailed();
    error InsufficientTreasury();
    error CannotDelegateToSelf();
    error DelegateNotMember();

    // ──────────────────────────────────────────────
    //  Modifiers
    // ──────────────────────────────────────────────

    modifier onlyMember() {
        if (!members[msg.sender]) revert NotMember();
        _;
    }

    // ──────────────────────────────────────────────
    //  Constructor
    // ──────────────────────────────────────────────

    /**
     * @notice Deploy a new Inner Circle DAO.
     * @param _afriRepAddress         Address of the AfriRep reputation contract.
     * @param _minReputationToCreate  Min rep score for the creator.
     * @param _minReputationToJoin    Min rep score for new members.
     * @param _name                   Name of the Inner Circle.
     * @param _description            Description of the circle's purpose.
     */
    constructor(
        address _afriRepAddress,
        uint256 _minReputationToCreate,
        uint256 _minReputationToJoin,
        string memory _name,
        string memory _description
    ) {
        afriRep = IAfriRep(_afriRepAddress);
        minReputationToCreate = _minReputationToCreate;
        minReputationToJoin = _minReputationToJoin;
        circleName = _name;
        circleDescription = _description;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _addMember(msg.sender);
    }

    // ──────────────────────────────────────────────
    //  Membership
    // ──────────────────────────────────────────────

    /**
     * @notice Add a new member to the Inner Circle.
     * @dev Only admin can add members. Member must meet the minimum reputation.
     * @param _newMember Address of the prospective member.
     */
    function addMember(address _newMember) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addMember(_newMember);
    }

    /**
     * @dev Internal member addition with reputation check.
     */
    function _addMember(address _newMember) internal {
        if (members[_newMember]) revert AlreadyMember();

        (, , uint256 reputation, , , ) = afriRep.getUserProfile(_newMember);
        if (reputation < minReputationToJoin) {
            revert ReputationTooLow(minReputationToJoin, reputation);
        }

        members[_newMember] = true;
        memberList.push(_newMember);

        emit MemberAdded(_newMember, reputation);
    }

    /**
     * @notice Remove a member from the Inner Circle (admin only).
     * @param _member Address to remove.
     */
    function removeMember(address _member) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!members[_member]) revert NotMember();

        members[_member] = false;

        // Remove from memberList
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        emit MemberRemoved(_member, msg.sender);
    }

    /**
     * @notice Leave the Inner Circle voluntarily.
     */
    function leaveCircle() external onlyMember {
        members[msg.sender] = false;

        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        emit MemberRemoved(msg.sender, msg.sender);
    }

    // ──────────────────────────────────────────────
    //  Delegation
    // ──────────────────────────────────────────────

    /**
     * @notice Delegate your voting power to another member.
     * @param _delegate Address to delegate to.
     */
    function delegateVote(address _delegate) external onlyMember {
        if (_delegate == msg.sender) revert CannotDelegateToSelf();
        if (!members[_delegate]) revert DelegateNotMember();

        votingDelegates[msg.sender] = _delegate;
        emit VoteDelegated(msg.sender, _delegate);
    }

    /**
     * @notice Remove your voting delegation.
     */
    function removeDelegation() external onlyMember {
        votingDelegates[msg.sender] = address(0);
        emit VoteDelegated(msg.sender, address(0));
    }

    // ──────────────────────────────────────────────
    //  Proposals
    // ──────────────────────────────────────────────

    /**
     * @notice Create a new governance proposal.
     * @param _title       Short title for the proposal.
     * @param _description Detailed description.
     * @param _amount      ETH amount to transfer (0 for non-financial proposals).
     * @param _recipient   Recipient of funds (address(0) for non-financial).
     * @return proposalId  The ID of the created proposal.
     */
    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _amount,
        address _recipient
    ) external onlyMember returns (uint256) {
        if (_amount > 0 && _amount > address(this).balance) {
            revert InsufficientTreasury();
        }

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

        emit ProposalCreated(proposalId, msg.sender, _title, _amount);
        return proposalId;
    }

    /**
     * @notice Cancel a proposal (only by proposer or admin, only before execution).
     * @param _proposalId ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (proposal.cancelled) revert ProposalAlreadyCancelled();
        if (proposal.proposer != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotProposer();
        }

        proposal.cancelled = true;
        emit ProposalCancelled(_proposalId, msg.sender);
    }

    /**
     * @notice Cast a vote on an active proposal.
     * @param _proposalId ID of the proposal.
     * @param _support    True = for, false = against.
     */
    function castVote(uint256 _proposalId, bool _support) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.cancelled) revert ProposalAlreadyCancelled();
        if (block.timestamp < proposal.voteStart) revert VotingNotStarted();
        if (block.timestamp > proposal.voteEnd) revert VotingEnded();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        proposal.hasVoted[msg.sender] = true;

        // Calculate voting weight: 1 base + delegations
        uint256 weight = 1;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (votingDelegates[memberList[i]] == msg.sender) {
                weight++;
            }
        }

        if (_support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }

        emit VoteCast(msg.sender, _proposalId, _support, weight);
    }

    /**
     * @notice Execute a proposal that has passed voting.
     * @dev Checks quorum (30% of members), majority, and not already executed.
     *      Transfers ETH to recipient if the proposal includes funding.
     * @param _proposalId ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant onlyMember {
        Proposal storage proposal = proposals[_proposalId];

        if (block.timestamp <= proposal.voteEnd) revert VotingNotEnded();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (proposal.cancelled) revert ProposalAlreadyCancelled();

        // Check quorum
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        uint256 quorumRequired = (memberList.length * QUORUM_PERCENTAGE) / 100;
        if (quorumRequired == 0) quorumRequired = 1;
        if (totalVotes < quorumRequired) {
            revert QuorumNotReached(quorumRequired, totalVotes);
        }

        // Check majority
        if (proposal.forVotes <= proposal.againstVotes) revert ProposalNotPassed();

        proposal.executed = true;

        // Execute fund transfer if applicable
        if (proposal.amount > 0 && proposal.recipient != address(0)) {
            if (address(this).balance < proposal.amount) revert InsufficientTreasury();

            (bool success, ) = payable(proposal.recipient).call{value: proposal.amount}("");
            if (!success) revert TransferFailed();
        }

        emit ProposalExecuted(_proposalId, msg.sender, proposal.amount);
    }

    // ──────────────────────────────────────────────
    //  View Functions
    // ──────────────────────────────────────────────

    /**
     * @notice Get the current state of a proposal.
     * @param _proposalId Proposal ID.
     * @return Current ProposalState enum value.
     */
    function getProposalState(uint256 _proposalId) external view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.cancelled) return ProposalState.Cancelled;
        if (proposal.executed) return ProposalState.Executed;
        if (block.timestamp < proposal.voteStart) return ProposalState.Pending;
        if (block.timestamp <= proposal.voteEnd) return ProposalState.Active;

        // Voting ended — check result
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        uint256 quorumRequired = (memberList.length * QUORUM_PERCENTAGE) / 100;
        if (quorumRequired == 0) quorumRequired = 1;

        if (totalVotes < quorumRequired || proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        }

        return ProposalState.Succeeded;
    }

    /// @notice Returns the total number of current members.
    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    /// @notice Returns the DAO's ETH treasury balance.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Check if an address is a member.
    function isMember(address _account) external view returns (bool) {
        return members[_account];
    }

    // ──────────────────────────────────────────────
    //  Treasury
    // ──────────────────────────────────────────────

    /// @notice Accept ETH deposits to the DAO treasury.
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }
}