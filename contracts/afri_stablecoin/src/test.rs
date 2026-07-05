#![cfg(test)]

use super::*;
use soroban_sdk::{testutils::Address as _, Address, Env, String};

#[test]
fn test_mint_with_fiat() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, AfriStablecoinContract);
    let client = AfriStablecoinContractClient::new(&env, &contract_id);

    let admin = Address::generate(&env);
    let updater = Address::generate(&env);
    let minter = Address::generate(&env);

    client.initialize(&admin, &updater, &minter);

    let currency = String::from_str(&env, "NGN");
    // Set exchange rate: 1500 NGN = 1 USD (1 AFD)
    client.update_rate(&currency, &1500);

    let user = Address::generate(&env);
    
    // User deposits 150,000 NGN. Should receive 100 AFD.
    client.mint_with_fiat(&user, &currency, &150000);

    assert_eq!(client.balance(&user), 100);
}
