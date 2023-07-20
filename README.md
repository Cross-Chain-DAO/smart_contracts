# Governor Smart Contract Documentation

[![Watch the video](https://i.imgur.com/PpqxUVp.jpg)](https://www.youtube.com/watch?v=tcxoGLWKKk8)

## Introduction

Governor is a decentralized governance smart contract that enables voting and execution of proposals on multiple blockchains using the Wormhole protocol. It allows users to participate in decision-making processes and shape the direction of the associated decentralized application (dApp). The contract supports both base proposals and cross-chain proposals, enabling communication and collaboration across different chains.

## Features

1. Multi-Chain Support: Governor is designed to work across multiple blockchains, allowing seamless governance across different ecosystems.

2. Staking and Voting: Users can stake their governance tokens to gain voting power and participate in decision-making processes.

3. Proposal Creation: Users can create new proposals by specifying target addresses, values, calldatas, and a description.

4. Flexible Voting Options: Voters can choose from three voting options: "ForVotes," "AgainstVotes," and "AbstrainVotes."

5. Cross-Chain Proposals: Governor supports cross-chain proposals that are created on other chains and communicated to this contract using the Wormhole protocol.

6. Vote Counting: After the voting period ends, votes from both the base chain and cross-chain proposals are counted to determine the proposal's outcome.

7. Proposal Execution: If a proposal receives more "ForVotes" than "AgainstVotes" and meets the quorum condition, it can be executed.

8. Broadcasting Fees: The contract calculates and quotes the fees required to broadcast messages to other chains through Wormhole.

## Smart Contract Details

### Functions

#### `addSupportedContract(uint16 chainId, address contractAddress)`

- Description: Adds a contract address as supported for a specific chain ID.
- Access: Only the contract owner can call this function.

#### `removeSupportedContract(uint16 chainId)`

- Description: Removes the support for a contract address on a specific chain.
- Access: Only the contract owner can call this function.

#### `setDuration(uint256 _duration)`

- Description: Sets the duration (in seconds) for the voting period of proposals.
- Access: Only the contract owner can call this function.

#### `stake(uint256 amount)`

- Description: Allows users to stake a specified amount of governance tokens to gain voting power.
- Access: Any user can call this function.

#### `createProposal(address[] targets, uint256[] values, bytes[] calldatas, string description)`

- Description: Creates a new base proposal with the provided target addresses, values, calldatas, and description.
- Access: Any user can call this function.

#### `voteOnBaseProposal(uint256 id, VoteTypes voteType)`

- Description: Casts a vote (ForVotes, AgainstVotes, or AbstrainVotes) on a base proposal.
- Access: Only users who have staked tokens can vote.

#### `voteOnCrossChainProposal(uint16 chainId, uint256 proposalId, VoteTypes voteType)`

- Description: Casts a vote (ForVotes, AgainstVotes, or AbstrainVotes) on a cross-chain proposal.
- Access: Only users who have staked tokens can vote.

#### `countVotes(uint256 id)`

- Description: Requests vote counting for a specific proposal after the voting period has ended.
- Access: Any user can call this function.

#### `executeProposal(uint256 id)`

- Description: Executes a base proposal if it meets the required conditions (more ForVotes than AgainstVotes and quorum condition).
- Access: Any user can call this function.

#### `unstake(uint256 amount)`

- Description: Allows users to unstake a specified amount of governance tokens and withdraw their tokens.
- Access: Any user can call this function.

### Modifiers

- `onlyActiveBaseProposal(uint256 id)`: Checks if a base proposal is active (voting period ongoing).
- `onlyActiveCrossChainProposal(uint16 chainId, uint256 proposalId)`: Checks if a cross-chain proposal is active (voting period ongoing).

### Events

Governor emits the following events to notify users and applications about important contract activities:

- `SupportChainAdded(uint16 chainId, address contractAddress)`: Triggered when a new contract address is added as supported for a specific chain ID.
- `SupportChainRemoved(uint16 chainId)`: Triggered when support for a contract address is removed from a specific chain ID.
- `DurationUpdated(uint256 duration)`: Triggered when the duration of the voting period is updated.
- `TokenStaked(address user, uint256 amount, uint256 totalStaked)`: Triggered when a user stakes governance tokens.
- `ProposalCreated(uint256 id, address proposer, address[] targets, uint256[] values, bytes[] calldatas, string description, uint256 startTime, uint256 endTime)`: Triggered when a new base proposal is created.
- `VotedOnBaseChainProposal(uint256 id, address voter, uint256 forVotes, uint256 againstVotes, uint256 abstrainVotes, uint256 voterForVotes, uint256 voterAgainstVotes, uint256 voterAbstrainVotes)`: Triggered when a user votes on a base proposal.
- `CrossChainProposalCreated(uint16 chainId, uint256 proposalId, uint256 startTime, uint256 endTime)`: Triggered when a new cross-chain proposal is created.
- `VotesSent(uint16 chainId, uint256 proposalId, uint256 forVotes, uint256 againstVotes, uint256 abstrainVotes)`: Triggered when votes are sent from another chain for a cross-chain proposal.
- `VotesReceived(uint16 chainId, uint256 proposalId, uint256 forVotes, uint256 againstVotes, uint256 abstrainVotes, uint256 voterForVotes, uint256 voterAgainstVotes, uint256 voterAbstrainVotes)`: Triggered when a user's votes are received from another chain for a cross-chain proposal.
- `TokenUnstaked(address user, uint256 amount, uint256 totalStaked)`: Triggered when a user unstakes governance tokens.

## Usage

Governor can be integrated into various decentralized applications to implement decentralized governance. Users can stake their governance tokens, create proposals, vote on proposals, and participate in shaping the project's future.

Governor is designed to work in conjunction with the Wormhole protocol, enabling cross-chain communication and collaboration. To use Governor effectively, ensure the contract is deployed and integrated with the required ERC20 governance token. Users must also be familiar with the supported contracts on different chains and follow the instructions to create cross-chain proposals.

## Disclaimer

Governor is a smart contract and should be used with caution. Before using this contract, carefully review the code and understand the implications of staking tokens, creating proposals, and voting on proposals. It is essential to thoroughly test the contract in a development environment before deploying it to the mainnet. 
