#![cfg(test)]

use super::*;
use soroban_sdk::{testutils::Address as _, Address, Env, String};

#[test]
fn test_register_and_vouch() {
    let env = Env::default();
    env.mock_all_auths(); // Bypass auth checks for simple testing

    let contract_id = env.register_contract(None, AfriRepContract);
    let client = AfriRepContractClient::new(&env, &contract_id);

    let admin = Address::generate(&env);
    client.initialize(&admin);

    let user1 = Address::generate(&env);
    let user2 = Address::generate(&env);

    // Register User 1
    client.register(&user1, &String::from_str(&env, "Alice"), &String::from_str(&env, "NGA"));
    
    // Register User 2
    client.register(&user2, &String::from_str(&env, "Bob"), &String::from_str(&env, "KEN"));

    let profile1 = client.get_profile(&user1);
    assert_eq!(profile1.reputation_score, 10);

    // Vouch across borders
    client.give_vouch(&user1, &user2, &5);

    let profile2 = client.get_profile(&user2);
    // Base 10 + (5 * 2) = 20
    assert_eq!(profile2.reputation_score, 20);
}

#[test]
fn test_admin_functions() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, AfriRepContract);
    let client = AfriRepContractClient::new(&env, &contract_id);

    let admin = Address::generate(&env);
    client.initialize(&admin);

    let user1 = Address::generate(&env);
    client.register(&user1, &String::from_str(&env, "Alice"), &String::from_str(&env, "NGA"));

    // Verify user
    client.verify_user(&user1);
    let profile1 = client.get_profile(&user1);
    assert!(profile1.is_verified);
}
