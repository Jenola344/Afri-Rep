// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IInnerCircleDAO — Interface for Inner Circle DAO
 * @author Afri Rep Contributors
 * @notice Interface for interacting with reputation-gated community DAOs.
 */
interface IInnerCircleDAO {
    // ──────────────────────────────────────────────
    //  Enums
    // ──────────────────────────────────────────────

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Executed,
        Cancelled
    }

    // ──────────────────────────────────────────────
    //  Events
    // ──────────────────────────────────────────────

    event MemberAdded(address indexed member, uint256 reputation);
    event MemberRemoved(address indexed member, address indexed removedBy);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 amount);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor, uint256 amount);
    event ProposalCancelled(uint256 indexed proposalId, address indexed canceller);
    event VoteDelegated(address indexed delegator, address indexed delegate);
    event TreasuryDeposit(address indexed sender, uint256 amount);

    // ──────────────────────────────────────────────
    //  Membership
    // ──────────────────────────────────────────────

    function addMember(address _newMember) external;
    function removeMember(address _member) external;
    function leaveCircle() external;
    function delegateVote(address _delegate) external;
    function removeDelegation() external;

    // ──────────────────────────────────────────────
    //  Proposals
    // ──────────────────────────────────────────────

    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _amount,
        address _recipient
    ) external returns (uint256);

    function cancelProposal(uint256 _proposalId) external;
    function castVote(uint256 _proposalId, bool _support) external;
    function executeProposal(uint256 _proposalId) external;

    // ──────────────────────────────────────────────
    //  View Functions
    // ──────────────────────────────────────────────

    function getProposalState(uint256 _proposalId) external view returns (ProposalState);
    function getMemberCount() external view returns (uint256);
    function getTreasuryBalance() external view returns (uint256);
    function isMember(address _account) external view returns (bool);
}
