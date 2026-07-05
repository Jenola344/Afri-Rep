#![no_std]

use soroban_sdk::{contract, contractimpl, contracttype, Address, Env, String};

#[cfg(test)]
mod test;

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ProposalState {
    Active,
    Executed,
    Defeated,
}

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Proposal {
    pub id: u32,
    pub proposer: Address,
    pub description: String,
    pub amount: i128,
    pub recipient: Address,
    pub for_votes: u32,
    pub against_votes: u32,
    pub state: ProposalState,
}

#[contracttype]
pub enum DataKey {
    Admin,
    ProposalCount,
    Proposal(u32),
    Member(Address),
    HasVoted(u32, Address), // (proposal_id, voter)
}

#[contract]
pub struct InnerCircleDAOContract;

#[contractimpl]
impl InnerCircleDAOContract {
    /// Initialize DAO
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("Already initialized");
        }
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::ProposalCount, &0u32);
        // Admin is implicitly a member
        env.storage().persistent().set(&DataKey::Member(admin.clone()), &true);
    }

    /// Add a member (Admin only)
    pub fn add_member(env: Env, new_member: Address) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();
        env.storage().persistent().set(&DataKey::Member(new_member), &true);
    }

    /// Create a proposal (Members only)
    pub fn create_proposal(env: Env, proposer: Address, description: String, amount: i128, recipient: Address) -> u32 {
        proposer.require_auth();
        let is_member: bool = env.storage().persistent().get(&DataKey::Member(proposer.clone())).unwrap_or(false);
        if !is_member { panic!("Only members can create proposals"); }

        let mut count: u32 = env.storage().instance().get(&DataKey::ProposalCount).unwrap();
        count += 1;

        let proposal = Proposal {
            id: count,
            proposer,
            description,
            amount,
            recipient,
            for_votes: 0,
            against_votes: 0,
            state: ProposalState::Active,
        };

        env.storage().persistent().set(&DataKey::Proposal(count), &proposal);
        env.storage().instance().set(&DataKey::ProposalCount, &count);

        count
    }

    /// Cast a vote (Members only)
    pub fn vote(env: Env, voter: Address, proposal_id: u32, support: bool) {
        voter.require_auth();
        let is_member: bool = env.storage().persistent().get(&DataKey::Member(voter.clone())).unwrap_or(false);
        if !is_member { panic!("Only members can vote"); }

        let vote_key = DataKey::HasVoted(proposal_id, voter.clone());
        if env.storage().persistent().has(&vote_key) {
            panic!("Already voted");
        }

        let mut proposal: Proposal = env.storage().persistent().get(&DataKey::Proposal(proposal_id)).unwrap_or_else(|| panic!("Proposal not found"));
        if proposal.state != ProposalState::Active {
            panic!("Proposal is not active");
        }

        if support {
            proposal.for_votes += 1;
        } else {
            proposal.against_votes += 1;
        }

        env.storage().persistent().set(&vote_key, &true);
        env.storage().persistent().set(&DataKey::Proposal(proposal_id), &proposal);
    }

    /// Execute a proposal (Anyone can call if votes pass)
    pub fn execute_proposal(env: Env, proposal_id: u32) {
        let mut proposal: Proposal = env.storage().persistent().get(&DataKey::Proposal(proposal_id)).unwrap_or_else(|| panic!("Proposal not found"));
        if proposal.state != ProposalState::Active {
            panic!("Proposal is not active");
        }

        // Simple majority logic
        if proposal.for_votes > proposal.against_votes {
            proposal.state = ProposalState::Executed;
            // Native XLM or Token transfer logic would go here.
            // Using `token::Client::new(&env, &token_address).transfer(...)`
        } else {
            proposal.state = ProposalState::Defeated;
        }

        env.storage().persistent().set(&DataKey::Proposal(proposal_id), &proposal);
    }

    pub fn get_proposal(env: Env, proposal_id: u32) -> Proposal {
        env.storage().persistent().get(&DataKey::Proposal(proposal_id)).unwrap_or_else(|| panic!("Proposal not found"))
    }
}
