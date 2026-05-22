# ERC20 Staking Rewards Protocol ⚡

This repository contains my practice implementation of a **Staking Rewards Protocol** built while learning about ERC20 tokens and DeFi mechanics through the advanced Solidity and Foundry content from Cyfrin Updraft.

This repository currently contains:

- ✅ Basic staking rewards implementation
- 🚧 Advanced production-style staking version (in progress)

---

# 🧠 Why I Built This

After learning the fundamentals of ERC20 tokens, I wanted to build something closer to real DeFi protocols like:

- Aave
- Curve
- Synthetix
- Convex

This project started as a simple staking contract to understand the complete staking flow:

1. Users stake ERC20 tokens
2. Rewards accumulate over time
3. Users claim rewards
4. Users withdraw stake + rewards

As I progressed, I realized real protocols use much more advanced accounting systems for gas efficiency and fairness — so I decided to build both versions:

- a beginner-friendly version
- and a more production-style implementation

---

# 📦 Basic Version Features

The basic staking contract includes:

- ERC20 token staking
- Reward token distribution
- Time-based reward calculation
- Claim rewards
- Withdraw staked tokens
- Exit function (withdraw + claim)
- Owner reward funding
- Configurable reward rate

Concepts practiced:

- `transferFrom`
- ERC20 approvals
- reward accounting
- state updates before interactions
- mappings
- timestamp calculations
- custom errors
- access control

---

# 🚀 Advanced Version (In Progress)

The advanced version is being upgraded with production-style reward accounting similar to modern DeFi protocols.

Planned features:

- `rewardPerTokenStored` mechanism
- `userRewardPerTokenPaid`
- gas-optimized reward calculations
- precision math handling
- reward snapshots
- improved security patterns
- reentrancy protection
- pausable staking
- event indexing improvements
- fuzz/invariant testing
- production-grade Foundry test suite

---

# 🛠 Tech Stack

- Solidity `^0.8.34`
- Foundry
- OpenZeppelin ERC20

---

# ⚠️ Note

This repository is for educational and practice purposes.

The contracts are not audited and should not be used in production.

---

# 👨‍💻 Learning Journey

This is part of my journey toward becoming a strong full-stack Web3 developer focused on:

- Smart Contract Development
- Solidity
- DeFi Protocols
- Foundry
- Next.js + Web3 integration

More advanced DeFi projects coming soon 🚀