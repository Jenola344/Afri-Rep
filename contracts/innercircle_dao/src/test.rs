#![cfg(test)]

use super::*;
use soroban_sdk::{testutils::Address as _, Address, Env, String};

#[test]
fn test_proposal_and_voting() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, InnerCircleDAOContract);
    let client = InnerCircleDAOContractClient::new(&env, &contract_id);

    let admin = Address::generate(&env);
    client.initialize(&admin);

    let member1 = Address::generate(&env);
    let member2 = Address::generate(&env);

    client.add_member(&member1);
    client.add_member(&member2);

    let desc = String::from_str(&env, "Fund new local tech hub");
    let recipient = Address::generate(&env);

    let prop_id = client.create_proposal(&member1, &desc, &5000, &recipient);

    // Vote
    client.vote(&member1, &prop_id, &true);
    client.vote(&member2, &prop_id, &true);

    let prop = client.get_proposal(&prop_id);
    assert_eq!(prop.for_votes, 2);
    assert_eq!(prop.state, ProposalState::Active);

    // Execute
    client.execute_proposal(&prop_id);
    
    let exec_prop = client.get_proposal(&prop_id);
    assert_eq!(exec_prop.state, ProposalState::Executed);
}
