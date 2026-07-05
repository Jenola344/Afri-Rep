#![no_std]

use soroban_sdk::{contract, contractimpl, contracttype, Address, Env, String};

#[cfg(test)]
mod test;

#[contracttype]
pub enum DataKey {
    Admin,
    Balance(Address),
    Allowance(Address, Address), // (from, spender)
    MaxTransferLimit, // Whale protection
    Exempt(Address),
}

#[contract]
pub struct AFDTokenContract;

#[contractimpl]
impl AFDTokenContract {
    /// Initialize the token with an admin and a max transfer limit.
    pub fn initialize(env: Env, admin: Address, max_limit: i128) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("Already initialized");
        }
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::MaxTransferLimit, &max_limit);
        env.storage().instance().set(&DataKey::Exempt(admin.clone()), &true);
    }

    /// Set exemption status for an address (e.g., DEX pool).
    pub fn set_exempt(env: Env, account: Address, exempt: bool) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();
        env.storage().instance().set(&DataKey::Exempt(account), &exempt);
    }

    /// Mint new tokens to `to`.
    pub fn mint(env: Env, to: Address, amount: i128) {
        if amount <= 0 { panic!("Amount must be positive"); }
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();

        let mut balance = Self::balance(env.clone(), to.clone());
        balance += amount;
        env.storage().persistent().set(&DataKey::Balance(to), &balance);
    }

    /// Burn tokens from `from`.
    pub fn burn(env: Env, from: Address, amount: i128) {
        if amount <= 0 { panic!("Amount must be positive"); }
        from.require_auth();

        let mut balance = Self::balance(env.clone(), from.clone());
        if balance < amount { panic!("Insufficient balance"); }
        balance -= amount;
        env.storage().persistent().set(&DataKey::Balance(from), &balance);
    }

    /// Transfer tokens from `from` to `to`.
    pub fn transfer(env: Env, from: Address, to: Address, amount: i128) {
        if amount <= 0 { panic!("Amount must be positive"); }
        from.require_auth();

        Self::check_whale_protection(&env, &from, amount);

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

    fn check_whale_protection(env: &Env, from: &Address, amount: i128) {
        let is_exempt: bool = env.storage().instance().get(&DataKey::Exempt(from.clone())).unwrap_or(false);
        if !is_exempt {
            let limit: i128 = env.storage().instance().get(&DataKey::MaxTransferLimit).unwrap_or(0);
            if limit > 0 && amount > limit {
                panic!("Transfer exceeds max limit (Whale Protection)");
            }
        }
    }
}
