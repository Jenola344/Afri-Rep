<p align="center">
  <h1 align="center">🌍 Afri Rep</h1>
  <p align="center">
    <strong>Africa's Digital Reputation Layer — Where Trust Unlocks Opportunity</strong>
  </p>
  <p align="center">
    <a href="https://github.com/Jenola344/Afri-Rep/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"></a>
    <a href="https://soroban.stellar.org/"><img src="https://img.shields.io/badge/Soroban-Rust-000000?logo=rust" alt="Soroban"></a>
    <a href="https://stellar.org/"><img src="https://img.shields.io/badge/Network-Stellar-000000?logo=stellar" alt="Stellar"></a>
    <a href="https://reactnative.dev/"><img src="https://img.shields.io/badge/React_Native-0.72-61DAFB?logo=react" alt="React Native"></a>
  </p>
</p>

---

## 🌟 Vision
In many African communities, traditional systems like **Ajo**, **Stokvel**, or **Iqub** rely entirely on social trust. **Afri Rep** modernizes this by bringing portable, community-verified reputation to the **Stellar blockchain**. We transform local trust into verifiable economic power, unlocking opportunities like borderless jobs, zero-collateral micro-loans, and seamless cross-border commerce across all 54 African nations.

## 🚀 Key Features

- **Portable Identity & Reputation**: Your 0-1000 Rep Score proves your reliability, built entirely on community vouches.
- **Cross-Border Trust Bridges**: A proprietary trust algorithm that discounts cross-border vouching fraud.
- **AfriDollar (AFD)**: A fast, low-cost pan-African stablecoin pegged to USD, powered by Stellar's high-speed consensus and integrated with local fiat on/off ramps.
- **Inner Circle DAOs**: Reputation-gated digital community savings groups with on-chain Soroban-powered treasury management.
- **Opportunity Marketplace**: High-paying jobs and gigs gated by minimum Rep Scores.

## 🏗️ Architecture

Afri Rep uses a modern tech stack centered on **Stellar Soroban** for high performance, extremely low fees, and robust security.

```mermaid
graph TD
    %% Styling
    classDef frontend fill:#3b82f6,stroke:#1d4ed8,stroke-width:2px,color:white;
    classDef sdk fill:#10b981,stroke:#047857,stroke-width:2px,color:white;
    classDef soroban fill:#f59e0b,stroke:#b45309,stroke-width:2px,color:white;
    classDef storage fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:white;
    classDef external fill:#64748b,stroke:#334155,stroke-width:2px,color:white;

    %% Components
    A[React Native App]:::frontend
    B[@stellar/freighter-api]:::sdk
    C[Stellar Soroban SDK]:::sdk
    
    %% Soroban Contracts
    subgraph Stellar Network [Stellar Network (Soroban Rust Contracts)]
        D[AfriRep Core Contract<br/>Reputation & Vouches]:::soroban
        E[InnerCircle DAO<br/>Governance]:::soroban
        F[AFD Stablecoin<br/>Stellar Asset]:::soroban
    end
    
    %% Storage & External
    G[IPFS / Pinata<br/>Evidences & Profiles]:::storage
    H[Mobile Money APIs<br/>Fiat Ramps]:::external

    %% Connections
    A -->|Sign Txns| B
    B <--> C
    C -->|Submit Txns| D
    C -->|Deploy/Vote| E
    C -->|Transfer XLM/AFD| F
    
    D -->|Check Profile/Rep| E
    
    A -->|Upload/Fetch| G
    H -->|Mint/Burn triggers| F
```

## 📜 Core Soroban Contracts (Rust)

1. **AfriRep Core (`afri_rep`)**: Manages user registration, profiles, and the core vouching mechanic. Calculates reputation points based on the origin of vouches.
2. **Innercircle DAO (`innercircle_dao`)**: Allows users to pool XLM/AFD into savings groups. Only users with a specific Rep Score can join or create proposals.
3. **AFD Token & Stablecoin (`afd_token`, `afri_stablecoin`)**: Stellar-native assets or Soroban SAC contracts for managing stable-value transfers across borders.

## 🛠️ Local Development Setup

### Prerequisites
- [Node.js](https://nodejs.org/) (v18+)
- [Rust](https://rustup.rs/) (v1.71+)
- [Soroban CLI](https://soroban.stellar.org/docs/getting-started/setup)

### 1. Install Dependencies
```bash
npm install
```

### 2. Build Soroban Contracts
```bash
npm run build
```
*(This navigates to the `contracts/` directory and runs `soroban contract build` to compile the Rust contracts to WebAssembly `*.wasm` files).*

### 3. Run Contract Tests
```bash
npm test
```
*(Executes `cargo test` in the Soroban workspace).*

### 4. Run the Mobile App
Currently set up to preview the UI components via Expo (simulated logic until Freighter mobile wallet integration is complete).
```bash
npx expo start
```

## 🤝 Contributing
We welcome contributions from the community! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

## 🛡️ Security
Security is a top priority. Read our [SECURITY.md](SECURITY.md) for details on how we protect the protocol and how to report vulnerabilities.

## 📄 License
This project is licensed under the [MIT License](LICENSE).
