# solidity-learning

Personal Solidity learning notes and contracts by [@krenshyax](https://x.com/krenshyax), deployed and tested on Base.

These are practice and portfolio contracts written while learning, not production software. Each one explores a specific concept: tokens, NFTs, governance, and an escrow state machine.

## Contracts

All source lives in [`contracts/`](./contracts):

- **`EscrowDemo.sol`** — hand-written marketplace escrow with a buyer / seller / arbiter state machine (Secured, Shipped, Delivered, Released, plus refund and dispute paths). Built step by step to understand payable, state machines, events, safe ETH transfers, and reentrancy.
- **`KrenshyaToken.sol`** — ERC20 with permit (KREN).
- **`KVT.sol`** — ERC20Votes governance token (contract `KrenshyaVoteToken`).
- **`KrenshyaGovernor.sol`** and **`MyTimelock.sol`** — OpenZeppelin Governor and TimelockController.
- **`BudapestBuilders.sol`** (BPST) and **`BudapestLearners.sol`** (BLRN) — ERC721 practice NFTs.
- **`Counter.sol`** and **`SimpleStorage.sol`** — hand-written basics.

## Deployments

- Base mainnet: [`deployments/base-mainnet.md`](./deployments/base-mainnet.md)
- Base Sepolia (testnet): [`deployments/base-sepolia.md`](./deployments/base-sepolia.md)

## License

[MIT](./LICENSE)
