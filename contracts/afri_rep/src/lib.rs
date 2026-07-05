#![no_std]

use soroban_sdk::{contract, contractimpl, contracttype, Address, Env, String, Symbol};

#[cfg(test)]
mod test;

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
    Paused,
    CountryMultiplier(String), // country code -> u32 (multiplier in percentage)
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
        env.storage().instance().set(&DataKey::Paused, &false);
    }

    /// Pause the contract (Admin only)
    pub fn pause(env: Env) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();
        env.storage().instance().set(&DataKey::Paused, &true);
    }

    /// Unpause the contract (Admin only)
    pub fn unpause(env: Env) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();
        env.storage().instance().set(&DataKey::Paused, &false);
    }

    /// Set country trust multiplier (Admin only)
    pub fn set_country_multiplier(env: Env, country_code: String, multiplier: u32) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();
        env.storage().instance().set(&DataKey::CountryMultiplier(country_code), &multiplier);
    }

    /// Verify a user (Admin only)
    pub fn verify_user(env: Env, user: Address) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();

        let key = DataKey::Profile(user.clone());
        let mut profile: UserProfile = env.storage().persistent().get(&key).unwrap_or_else(|| panic!("User not found"));
        profile.is_verified = true;
        env.storage().persistent().set(&key, &profile);
    }

    /// Register a new user profile.
    pub fn register(env: Env, user: Address, name: String, country_code: String) {
        let paused: bool = env.storage().instance().get(&DataKey::Paused).unwrap_or(false);
        if paused { panic!("Contract is paused"); }

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
        let paused: bool = env.storage().instance().get(&DataKey::Paused).unwrap_or(false);
        if paused { panic!("Contract is paused"); }

        from.require_auth();

        if from == to {
            panic!("Cannot self vouch");
        }
        if confidence < 1 || confidence > 5 {
            panic!("Invalid confidence level");
        }

        let from_key = DataKey::Profile(from.clone());
        let from_profile: UserProfile = env.storage().persistent().get(&from_key).unwrap_or_else(|| panic!("Voucher not registered"));

        let to_key = DataKey::Profile(to.clone());
        let mut to_profile: UserProfile = env.storage().persistent().get(&to_key).unwrap_or_else(|| panic!("Recipient not registered"));

        // Calculate reputation gain based on country multiplier
        let default_mult = 100u32;
        let mult = env.storage().instance().get(&DataKey::CountryMultiplier(from_profile.country_code.clone())).unwrap_or(default_mult);
        
        let mut gain = confidence * 2;
        
        // If they are from different countries, apply cross-border trust multiplier
        if from_profile.country_code != to_profile.country_code {
            gain = (gain * mult) / 100;
        }

        to_profile.reputation_score += gain;
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
