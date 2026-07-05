#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, Address, Env, String, Symbol};

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UserProfile {
    pub name: String,
    pub country_code: String,
    pub reputation_score: u32,
    pub is_verified: bool,
}

#[contracttype]
pub enum DataKey {
    Profile(Address),
    Admin,
}

#[contract]
pub struct AfriRepContract;

#[contractimpl]
impl AfriRepContract {
    /// Initialize the contract with an admin.
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("Already initialized");
        }
        env.storage().instance().set(&DataKey::Admin, &admin);
    }

    /// Register a new user profile.
    pub fn register(env: Env, user: Address, name: String, country_code: String) {
        user.require_auth();

        let key = DataKey::Profile(user.clone());
        if env.storage().persistent().has(&key) {
            panic!("User already registered");
        }

        let profile = UserProfile {
            name,
            country_code,
            reputation_score: 10, // Base reputation
            is_verified: false,
        };

        env.storage().persistent().set(&key, &profile);
        
        env.events().publish((Symbol::new(&env, "register"), user), profile);
    }

    /// Give a vouch to another user to increase their reputation.
    pub fn give_vouch(env: Env, from: Address, to: Address, confidence: u32) {
        from.require_auth();

        if from == to {
            panic!("Cannot self vouch");
        }
        if confidence < 1 || confidence > 5 {
            panic!("Invalid confidence level");
        }

        let to_key = DataKey::Profile(to.clone());
        let mut to_profile: UserProfile = env
            .storage()
            .persistent()
            .get(&to_key)
            .unwrap_or_else(|| panic!("Recipient not registered"));

        // Simplistic reputation math for the Stellar demo
        to_profile.reputation_score += confidence * 2;
        if to_profile.reputation_score > 1000 {
            to_profile.reputation_score = 1000;
        }

        env.storage().persistent().set(&to_key, &to_profile);

        env.events().publish(
            (Symbol::new(&env, "vouch"), from, to),
            confidence,
        );
    }

    /// Retrieve a user's profile.
    pub fn get_profile(env: Env, user: Address) -> UserProfile {
        env.storage()
            .persistent()
            .get(&DataKey::Profile(user))
            .unwrap_or_else(|| panic!("User not found"))
    }
}
