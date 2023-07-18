// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "./wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "./wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import "./wormhole-solidity-sdk/Utils.sol";

contract Treasury is Ownable, IWormholeReceiver {
    struct Proposal {
        uint256 id;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        bytes32 descriptionHash;
        bool executed;
        bool votesRequested;
        uint256 startTime;
        uint256 endTime;
    }

    enum MessageType {
        ProposalCreated,
        RequestVotes,
        VotesInfo
    }

    struct VoteCount {
        bool counted;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    mapping(uint256 => Proposal) public proposals; // f: proposalId -> proposal
    mapping(uint256 => mapping(uint16 => VoteCount)) public votes; // f: proposalId, chainId -> votes
    uint256 public totalProposals;
    uint256 public totalSupportedVotingChains;
    uint16[] public supportedVotingChainIds;
    mapping(uint16 => address) public votingContractOnChainId;
    uint256 public duration;

    uint256 constant GAS_LIMIT = 50_000;
    IWormholeRelayer public immutable wormholeRelayer;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        string description,
        uint256 startTime,
        uint256 endTime
    );

    event VotesRequested(uint256 indexed proposalId, address indexed requester);

    event VotingContractAdded(
        uint256 indexed chainId,
        address indexed votingContractAddress
    );

    event VoteCounted(
        uint256 proposalId,
        uint16 sourceChain,
        uint256 votesFor,
        uint256 votesAgainst
    );

    error VotingContractAlreadyAdded();
    error VotingContractCannotBeZeroAddress();
    error VotesNotCountedYet();
    error ProposalAlreadyExecuted();
    error ProposalRejected();
    error InvalidFeesPaid();
    error OnlyRelayerAllowed();
    error OnlyVotingContracts();
    error InvalidProposalId();
    error VotingPeriodNotEnded();
    error VotesAlreadyRequested();

    constructor(uint256 _duration, address _wormholeRelayer) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        duration = _duration;
    }

    function addVotingContract(
        address votingContract,
        uint16 votingChainId
    ) public onlyOwner {
        if (votingContact == address(0))
            revert VotingContractCannotBeZeroAddress();
        if (votingContractOnChainId[votingChainId] == votingContact)
            revert VotingContractAlreadyAdded();
        votingContractOnChainId[votingChainId] = votingContact;
        emit VotingContractAdded(votingChainId, votingContract);
    }

    // function _processMessageFromChild(bytes calldata data) internal override {
    //     uint256 id = abi.decode(data, (uint256));
    //     execute(id);
    // }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public payable {
        if (quoteBroadcastingFees() != msg.value) revert InvalidFeesPaid();
        uint256 id = totalProposals++;
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp + duration;
        proposals[id] = Proposal({
            id: id,
            targets: targets,
            values: values,
            calldatas: calldatas,
            descriptionHash: keccak256(bytes(description)),
            executed: false,
            votesRequested: false,
            startTime: startTime,
            endTime: endTime
        });

        // send the message to the voting chain
        bytes memory message = abi.encode(id, startTime, endTime);
        broadcastMessageToVotingContracts(message);

        emit ProposalCreated(
            id,
            msg.sender,
            targets,
            values,
            new string[](targets.length),
            calldatas,
            description,
            startTime,
            endTime
        );
    }

    function countVotes(uint256 id) public {
        if (id >= totalProposals) revert InvalidProposalId();
        Proposal memory proposal = proposals[id];
        if (proposal.endTime > block.timestamp) revert VotingPeriodNotEnded();
        if (proposal.votesRequested) revert VotesAlreadyRequested();

        proposals[id].votesRequested = true;

        // send the message to the voting chain
        bytes memory message = abi.encode(id);
        broadcastMessageToVotingContracts(message);

        emit VotesRequested(id, msg.sender);
    }

    function execute(uint256 id) public {
        Proposal storage proposal = proposals[id];
        if (proposal.executed) revert ProposalAlreadyExecuted();
        VoteCount memory voteCounts;
        voteCounts.counted = true;
        uint256 m_totalSupportedVotingChains = totalSupportedVotingChains;
        for (uint256 i = 0; i < m_totalSupportedVotingChains; i++) {
            uint16 chainId = supportedVotingChainIds[i];
            VoteCount memory chainVoteCount = votes[proposalId][chainId];
            if (!chainVoteCount.counted) voteCounts.counted = false;
            chainVoteCount.votesFor += chainVoteCount.votesFor;
            chainVoteCount.votesAgainst += chainVoteCount.votesAgainst;
        }
        if (!voteCounts.counted) revert VotesNotCountedYet();

        if (voteCounts.votesFor < voteCounts.votesAgainst)
            revert ProposalRejected();

        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, bytes memory returndata) = proposal.targets[i].call{
                value: proposal.values[i]
            }(proposal.calldatas[i]);
            Address.verifyCallResult(
                success,
                returndata,
                "Governer: call reverted without message"
            );
        }
    }

    function broadcastMessageToVotingContracts(
        MessageType messageType,
        bytes memory message
    ) internal {
        // TODO: check if the voting period is over, and also if not broadcasted earlier
        if (quoteBroadcastingFees() != msg.value) revert InvalidFeesPaid();
        uint256 m_totalSupportedVotingChains = totalSupportedVotingChains;
        for (uint256 i = 0; i < m_totalSupportedVotingChains; i++) {
            uint16 chainId = supportedVotingChainIds[i];
            address votingContractAddress = votingContractOnChainId[chainId];
            uint256 cost = getChainCost(targetChainId);
            wormholeRelayer.sendPayloadToEvm{value: cost}(
                chainId,
                votingContractAddress,
                abi.encode(messageType, message), // payload
                0, // no receiver value needed since we're just passing a message
                GAS_LIMIT
            );
        }
    }

    function quoteBroadcastingFees() public view returns (uint256 cost) {
        uint256 m_totalSupportedVotingChains = totalSupportedVotingChains;
        for (uint256 i = 0; i < m_totalSupportedVotingChains; i++) {
            uint16 targetChainId = supportedVotingChainIds[i];
            cost += getChainCost(targetChainId);
        }
    }

    function getChainCost(uint16 chainId) internal view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }

    function isVotesCountingDone(
        uint256 proposalId
    ) public view returns (bool) {
        uint256 m_totalSupportedVotingChains = totalSupportedVotingChains;
        for (uint256 i = 0; i < m_totalSupportedVotingChains; i++) {
            uint16 chainId = supportedVotingChainIds[i];
            if (!votes[proposalId][chainId].counted) return false;
        }
        return true;
    }

    // receiving messages from wormhole
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32 senderContractBytes32, // address that called 'sendPayloadToEvm' (HelloWormhole contract address)
        uint16 sourceChain,
        bytes32 // deliveryHash - this can be stored in a mapping deliveryHash => bool to prevent duplicate deliveries
    ) public payable override {
        if (msg.sender != address(wormholeRelayer)) revert OnlyRelayerAllowed();
        address senderContractAddress = fromWormholeFormat(
            senderContractBytes32
        );
        if (votingContractOnChainId[sourceChain] != senderContractAddress)
            revert OnlyVotingContracts();
        (MessageType messageType, bytes memory message) = abi.decode(
            payload,
            (MessageType, bytes)
        );
        (uint256 proposalId, uint256 votesFor, uint256 votesAgainst) = abi
            .decode(message, (uint256, uint256, uint256));
        VoteCount storage voteInfo = votes[proposalId][sourceChain];
        voteInfo.counted = true;
        voteInfo.votesFor = votesFor;
        voteInfo.votesAgainst = votesAgainst;
        emit VoteCounted(proposalId, sourceChain, votesFor, votesAgainst);
    }
}
