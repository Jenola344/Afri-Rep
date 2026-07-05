#![cfg(test)]

use super::*;
use soroban_sdk::{testutils::Address as _, Address, Env};

#[test]
fn test_mint_and_transfer() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, AFDTokenContract);
    let client = AFDTokenContractClient::new(&env, &contract_id);

    let admin = Address::generate(&env);
    let max_limit = 1000;
    client.initialize(&admin, &max_limit);

    let user1 = Address::generate(&env);
    let user2 = Address::generate(&env);

    // Mint 5000 to admin (exempt)
    client.mint(&admin, &5000);
    assert_eq!(client.balance(&admin), 5000);

    // Admin transfers 2000 to user1 (bypasses limit because admin is exempt)
    client.transfer(&admin, &user1, &2000);
    assert_eq!(client.balance(&user1), 2000);

    // User1 transfers 500 to user2 (under limit)
    client.transfer(&user1, &user2, &500);
    assert_eq!(client.balance(&user1), 1500);
    assert_eq!(client.balance(&user2), 500);
}

#[test]
#[should_panic(expected = "Transfer exceeds max limit")]
fn test_whale_protection() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, AFDTokenContract);
    let client = AFDTokenContractClient::new(&env, &contract_id);

    let admin = Address::generate(&env);
    client.initialize(&admin, &1000);

    let user1 = Address::generate(&env);
    let user2 = Address::generate(&env);

    // Give user1 2000 tokens (by minting to them as admin)
    client.mint(&user1, &2000);

    // User1 tries to transfer 1500 tokens (over limit)
    client.transfer(&user1, &user2, &1500);
}
