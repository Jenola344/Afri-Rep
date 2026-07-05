# Security Policy 🔒

## Reporting a Vulnerability

The Afri Rep team takes security seriously. If you discover a security vulnerability, please report it responsibly.

### ⚠️ Do NOT

- Open a public GitHub issue for security vulnerabilities.
- Exploit the vulnerability on any live deployment.
- Share the vulnerability publicly before it's been addressed.

### ✅ Do

1. **Email us** at security@afrirep.io with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact assessment
   - Suggested fix (if any)

2. **Encrypt sensitive details** using our PGP key (available on request).

3. **Allow us time** — We aim to respond within **48 hours** and patch critical issues within **7 days**.

## Scope

### In Scope

| Component | Description |
|-----------|-------------|
| **AfriRep.sol** | Core reputation contract |
| **AfriStablecoin.sol** | AfriDollar stablecoin |
| **AFD Token.sol** | AFD governance token |
| **InnercircleDAO.sol** | DAO governance contract |
| **Frontend App** | React Native mobile application |
| **API Endpoints** | Backend services and APIs |

### Out of Scope

- Third-party dependencies (report to their maintainers)
- Social engineering attacks
- Denial of service attacks
- Issues in test/development environments only

## Security Measures

### Smart Contracts

- **Upgradeable Proxies**: Core contracts use OpenZeppelin's upgradeable pattern for emergency patches.
- **Access Control**: Role-based permissions (ADMIN, VALIDATOR, MINTER, BURNER).
- **Reentrancy Guards**: All external-facing state-changing functions are protected.
- **Pausable**: Emergency pause capability on all critical contracts.
- **Input Validation**: Strict validation on all user inputs.
- **Time Locks**: Administrative actions subject to time delays.

### Infrastructure

- **Data Sovereignty**: User data stored in African data centers.
- **Encryption**: All data encrypted at rest and in transit.
- **Key Management**: Hardware security modules for critical keys.

## Audit Status

| Contract | Audit Status | Auditor | Date |
|----------|-------------|---------|------|
| AfriRep.sol | 🟡 Pending | — | — |
| AfriStablecoin.sol | 🟡 Pending | — | — |
| AFD Token.sol | 🟡 Pending | — | — |
| InnercircleDAO.sol | 🟡 Pending | — | — |

> We are actively seeking audit partners. If you're an auditing firm interested in supporting African blockchain infrastructure, please reach out.

## Bug Bounty

We are planning a formal bug bounty program. In the meantime, responsible disclosures will be acknowledged in our contributors list and may be eligible for rewards at our discretion.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x.x | ✅ Active |
| < 1.0 | ❌ No longer supported |

---

**Thank you for helping keep Afri Rep secure for millions of African users.** 🌍🔐
