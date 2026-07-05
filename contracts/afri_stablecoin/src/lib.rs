#![no_std]

use soroban_sdk::{contract, contractimpl, contracttype, Address, Env, String};

#[cfg(test)]
mod test;

#[contracttype]
pub enum DataKey {
    Admin,
    RateUpdater,
    Minter,
    Balance(Address),
    FiatRate(String), // Fiat currency code (e.g., "NGN") -> Exchange rate (u32)
}

#[contract]
pub struct AfriStablecoinContract;

#[contractimpl]
impl AfriStablecoinContract {
    /// Initialize the stablecoin with admin roles.
    pub fn initialize(env: Env, admin: Address, rate_updater: Address, minter: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("Already initialized");
        }
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::RateUpdater, &rate_updater);
        env.storage().instance().set(&DataKey::Minter, &minter);
    }

    /// Update the exchange rate for a fiat currency (RateUpdater only)
    pub fn update_rate(env: Env, currency_code: String, rate: u32) {
        let updater: Address = env.storage().instance().get(&DataKey::RateUpdater).unwrap();
        updater.require_auth();
        env.storage().instance().set(&DataKey::FiatRate(currency_code), &rate);
    }

    /// Mint AFD Stablecoins equivalent to a deposited fiat amount (Minter only)
    pub fn mint_with_fiat(env: Env, to: Address, currency_code: String, fiat_amount: u32) {
        let minter: Address = env.storage().instance().get(&DataKey::Minter).unwrap();
        minter.require_auth();

        let rate: u32 = env.storage().instance().get(&DataKey::FiatRate(currency_code.clone())).unwrap_or_else(|| panic!("Rate not found for currency"));
        
        // Simple conversion: fiat_amount / rate = AFD amount
        let amount = (fiat_amount / rate) as i128;
        if amount <= 0 { panic!("Amount too small"); }

        let mut balance = Self::balance(env.clone(), to.clone());
        balance += amount;
        env.storage().persistent().set(&DataKey::Balance(to), &balance);
    }

    /// Standard transfer
    pub fn transfer(env: Env, from: Address, to: Address, amount: i128) {
        if amount <= 0 { panic!("Amount must be positive"); }
        from.require_auth();

        let mut from_balance = Self::balance(env.clone(), from.clone());
        if from_balance < amount { panic!("Insufficient balance"); }
        
        from_balance -= amount;
        env.storage().persistent().set(&DataKey::Balance(from), &from_balance);

        let mut to_balance = Self::balance(env.clone(), to.clone());
        to_balance += amount;
        env.storage().persistent().set(&DataKey::Balance(to), &to_balance);
    }

    /// Get balance of `account`.
    pub fn balance(env: Env, account: Address) -> i128 {
        env.storage().persistent().get(&DataKey::Balance(account)).unwrap_or(0)
    }
}
