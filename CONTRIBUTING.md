# Contributing to Afri Rep 🌍

Thank you for your interest in contributing to Afri Rep! We're building Africa's digital reputation layer, and every contribution matters.

## 🤝 Code of Conduct

By participating in this project, you agree to uphold our values:

- **Ubuntu** — "I am because we are." Treat every contributor with respect.
- **Inclusivity** — We welcome contributors from every African nation and the global community.
- **Transparency** — Open communication, honest feedback, constructive criticism.
- **Quality** — We build for 1.4 billion people. Every line of code matters.

## 🚀 Getting Started

### Prerequisites

- **Node.js** >= 18.x
- **npm** >= 9.x or **yarn** >= 1.22
- **Hardhat** (for smart contract development)
- **Expo CLI** (for mobile app development)

### Setup

```bash
# Clone the repository
git clone https://github.com/Jenola344/Afri-Rep.git
cd Afri-Rep

# Install dependencies
npm install

# Run tests
npm test

# Start mobile app (Expo)
npm start
```

### Smart Contract Development

```bash
# Compile contracts
npx hardhat compile

# Run contract tests
npx hardhat test

# Deploy to local network
npx hardhat run local.ts --network localhost
```

## 📝 How to Contribute

### Reporting Bugs

1. Check existing [Issues](https://github.com/Jenola344/Afri-Rep/issues) to avoid duplicates.
2. Use the bug report template.
3. Include: steps to reproduce, expected behavior, actual behavior, environment details.

### Suggesting Features

1. Open an issue with the `feature-request` label.
2. Describe the use case, especially how it benefits African users.
3. If proposing a smart contract change, include a technical specification.

### Submitting Pull Requests

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. **Write clean code** following our style guidelines (see below).
3. **Add tests** for any new functionality.
4. **Update documentation** if your change affects the public API or user experience.
5. **Submit a PR** against the `main` branch with a clear description.

### PR Review Process

- All PRs require at least **1 approval** before merging.
- Smart contract changes require **2 approvals** and a security review.
- We aim to review PRs within **48 hours**.

## 🎨 Style Guidelines

### Solidity

- Follow the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html).
- Use NatSpec comments for all public/external functions.
- Maximum contract size: stay well under the 24KB limit.
- Always add events for state-changing operations.

### TypeScript / React Native

- Use functional components with hooks.
- Follow the existing theme system for all styling.
- Add proper TypeScript types — avoid `any`.
- Use meaningful component and variable names.

### Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/):
  ```
  feat: add cross-border vouch multiplier
  fix: correct reputation decay calculation
  docs: update README with deployment guide
  test: add edge cases for DAO voting
  ```

## 🌍 Localization

Afri Rep serves 54 African nations. When adding user-facing text:

- Use the localization system (don't hardcode strings).
- Consider RTL support for Arabic-speaking North Africa.
- Test with longer text strings (French and Portuguese tend to be longer than English).

## 🔒 Security

- **Never** commit private keys, mnemonics, or API secrets.
- Report security vulnerabilities privately — see [SECURITY.md](SECURITY.md).
- Smart contract changes must include test coverage for edge cases.

## 📊 Areas We Need Help

- **Smart Contract Auditing** — Security reviews and gas optimization
- **Frontend Development** — React Native UI/UX improvements
- **Localization** — Translations for African languages (Swahili, Yoruba, Hausa, Amharic, etc.)
- **Documentation** — API docs, tutorials, integration guides
- **Testing** — Expanding test coverage across all components

---

**Thank you for helping build Africa's trust economy!** 🌍💚
