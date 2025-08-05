# VortexDAO - Autonomous Treasury Management Protocol

[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-purple)](https://stacks.co)
[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-blue)](https://clarity-lang.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## Overview

VortexDAO is a sophisticated decentralized autonomous organization (DAO) that enables community-driven treasury management with advanced governance mechanisms, time-locked deposits, and democratic proposal execution on the Stacks blockchain. The protocol represents the next evolution in decentralized finance governance, combining traditional treasury management with cutting-edge blockchain technology.

## Key Features

### 🏛️ **Decentralized Governance**

- **Weighted Voting System**: Voting power proportional to staked STX tokens
- **Proposal Creation**: Community-driven funding initiatives and resource allocation
- **Democratic Decision Making**: Transparent voting with anti-spam mechanisms

### 🔒 **Security & Safety**

- **Time-locked Deposits**: Security lock periods to prevent immediate withdrawals
- **Minimum Thresholds**: Anti-spam protection with minimum deposit requirements
- **Proposal Validation**: Comprehensive input validation and execution safeguards
- **Double-voting Prevention**: Built-in mechanisms to ensure vote integrity

### 💰 **Treasury Management**

- **STX Staking**: Members stake STX to gain governance tokens and voting power
- **Automated Fund Distribution**: Execute approved proposals with treasury funds
- **Balance Tracking**: Real-time monitoring of member balances and total supply

### ⏰ **Time-based Controls**

- **Configurable Voting Periods**: 1-14 day voting duration range
- **Lock Period Management**: Secure time-locks for deposit withdrawals
- **Proposal Expiration**: Automatic proposal lifecycle management

## Technical Architecture

### Smart Contract Structure

```
VortexDAO Contract
├── Protocol Constants
│   ├── Error Codes (u100-u117)
│   └── Governance Parameters
├── State Variables
│   ├── Total Supply Tracking
│   ├── Minimum Deposit Rules
│   └── Lock Period Configuration
├── Data Structures
│   ├── Member Balances
│   ├── Deposit Records
│   ├── Proposal Registry
│   └── Vote Tracking
└── Functions
    ├── Core Operations
    ├── Governance Functions
    └── Read-only Queries
```

### Core Data Types

#### Member Deposits

```clarity
{
  amount: uint,           ;; Staked STX amount
  lock-until: uint,      ;; Block height when withdrawal allowed
  last-reward-block: uint ;; Last reward calculation block
}
```

#### Governance Proposals

```clarity
{
  proposer: principal,          ;; Proposal creator
  description: string-ascii,    ;; Proposal description (max 256 chars)
  amount: uint,                ;; Requested funding amount
  target: principal,           ;; Funding recipient
  expires-at: uint,            ;; Voting deadline block height
  executed: bool,              ;; Execution status
  yes-votes: uint,             ;; Total positive votes
  no-votes: uint               ;; Total negative votes
}
```

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks development toolkit
- [Node.js](https://nodejs.org/) v16+ for testing
- [Stacks Wallet](https://www.hiro.so/wallet) for mainnet interaction

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/grace-obong/VortexDAO.git
   cd VortexDAO
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Verify contract syntax**

   ```bash
   clarinet check
   ```

4. **Run tests**

   ```bash
   npm test
   ```

## Usage Guide

### For DAO Members

#### 1. Join the DAO by Staking STX

```clarity
;; Stake 10 STX to join the DAO
(contract-call? .VortexDAO deposit u10000000)
```

#### 2. Create a Governance Proposal

```clarity
;; Propose funding for a community project
(contract-call? .VortexDAO create-proposal 
  "Fund community hackathon"
  u5000000          ;; 5 STX requested
  'SP1234...        ;; Recipient address
  u1440             ;; 1 day voting period
)
```

#### 3. Vote on Proposals

```clarity
;; Vote yes on proposal #1
(contract-call? .VortexDAO vote u1 true)

;; Vote no on proposal #1
(contract-call? .VortexDAO vote u1 false)
```

#### 4. Execute Approved Proposals

```clarity
;; Execute proposal #1 (after voting period ends)
(contract-call? .VortexDAO execute-proposal u1)
```

#### 5. Withdraw Staked STX

```clarity
;; Withdraw 5 STX after lock period
(contract-call? .VortexDAO withdraw u5000000)
```

### For Developers

#### Query Functions

```clarity
;; Check member balance
(contract-call? .VortexDAO get-balance 'SP1234...)

;; Get proposal details
(contract-call? .VortexDAO get-proposal u1)

;; Check vote status
(contract-call? .VortexDAO get-vote u1 'SP1234...)

;; View deposit information
(contract-call? .VortexDAO get-deposit-info 'SP1234...)

;; Get total token supply
(contract-call? .VortexDAO get-total-supply)
```

## Configuration Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `minimum-deposit` | 1,000,000 µSTX (1 STX) | Minimum stake to join DAO |
| `lock-period` | 1,440 blocks (~10 days) | Withdrawal lock duration |
| `minimum-duration` | 144 blocks (~1 day) | Minimum voting period |
| `maximum-duration` | 20,160 blocks (~14 days) | Maximum voting period |

## Security Considerations

### Access Controls

- **Owner-only Functions**: Contract initialization restricted to deployer
- **Member Validation**: Voting requires active stake in the DAO
- **Proposal Validation**: Comprehensive input sanitization

### Economic Security

- **Time Locks**: Prevent immediate fund extraction
- **Minimum Stakes**: Reduce spam and ensure skin in the game
- **Voting Power**: Proportional to economic commitment

### Technical Security

- **Error Handling**: Comprehensive error codes for debugging
- **State Validation**: Consistent state checks throughout execution
- **Overflow Protection**: Safe arithmetic operations

## Error Codes Reference

| Code | Error | Description |
|------|-------|-------------|
| u100 | `err-owner-only` | Function restricted to contract owner |
| u101 | `err-not-initialized` | Contract not yet initialized |
| u102 | `err-already-initialized` | Contract already initialized |
| u103 | `err-insufficient-balance` | Insufficient token balance |
| u104 | `err-invalid-amount` | Invalid amount parameter |
| u105 | `err-unauthorized` | User not authorized for operation |
| u106 | `err-proposal-not-found` | Proposal ID does not exist |
| u107 | `err-proposal-expired` | Proposal voting period ended |
| u108 | `err-already-voted` | User already voted on proposal |
| u109 | `err-below-minimum` | Amount below minimum threshold |
| u110 | `err-locked-period` | Funds still in lock period |
| u111 | `err-transfer-failed` | STX transfer failed |
| u112 | `err-invalid-duration` | Invalid voting duration |
| u113 | `err-zero-amount` | Amount cannot be zero |
| u114 | `err-invalid-target` | Invalid target address |
| u115 | `err-invalid-description` | Invalid proposal description |
| u116 | `err-invalid-proposal-id` | Invalid proposal ID |
| u117 | `err-invalid-vote` | Invalid vote parameter |

## Testing

The project includes comprehensive test coverage using Vitest and Clarinet testing framework:

```bash
# Run all tests
npm test

# Run specific test file
npx vitest tests/VortexDAO.test.ts

# Check contract syntax
clarinet check
```

### Test Coverage Areas

- ✅ Contract initialization
- ✅ Member deposit and withdrawal flows
- ✅ Proposal creation and validation
- ✅ Voting mechanisms and tallying
- ✅ Proposal execution logic
- ✅ Error handling and edge cases
- ✅ Security and access controls

## Deployment

### Local Development (Clarinet)

```bash
clarinet integrate
```

### Testnet Deployment

```bash
clarinet publish --testnet
```

### Mainnet Deployment

```bash
clarinet publish --mainnet
```

## Roadmap

### Phase 1: Core Functionality ✅

- [x] Basic DAO operations
- [x] Proposal system
- [x] Voting mechanisms
- [x] Treasury management

### Phase 2: Enhanced Features 🚧

- [ ] Delegation mechanisms
- [ ] Reward distribution
- [ ] Multi-signature proposals
- [ ] Proposal categories

### Phase 3: Advanced Governance 📋

- [ ] Quadratic voting
- [ ] Reputation system
- [ ] Cross-chain integration
- [ ] DAO treasury strategies

## Contributing

We welcome contributions to VortexDAO! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code style and standards
- Testing requirements
- Pull request process
- Issue reporting

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `npm test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Stacks Foundation](https://stacks.org) for the blockchain infrastructure
- [Hiro Systems](https://hiro.so) for development tools and documentation
- The Clarity community for language development and best practices

---

**VortexDAO** - *Empowering communities through decentralized treasury management*

Built with ❤️ on Stacks blockchain
