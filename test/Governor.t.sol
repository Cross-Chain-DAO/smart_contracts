// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Governor.sol";

import {WormholeRelayerBasicTest, ERC20Mock} from "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

contract GovernorTest is WormholeRelayerBasicTest {
    Governor governor1;
    Governor governor2;
    ERC20Mock token1;
    ERC20Mock token2;

    address[] testTargets1;
    address[] testTargets2;
    uint256[] testValues1;
    uint256[] testValues2;
    bytes[] testCalldatas1;
    bytes[] testCalldatas2;

    address acc1;
    address acc2;
    address acc3;

    function setUpSource() public override {
        token1 = new ERC20Mock("T1", "T1");
        governor1 = new Governor(address(token1), address(relayerSource));
    }

    function setUpTarget() public override {
        token2 = new ERC20Mock("T2", "T2");
        governor2 = new Governor(address(token2), address(relayerTarget));
    }

    // function testConnectContracts() public {
    //     governor1.addSupportedContract(targetChain, address(governor2));
    //     vm.selectFork(targetFork);
    //     governor2.addSupportedContract(sourceChain, address(governor1));
    // }

    function _connectAllContracts() internal {
        governor1.addSupportedContract(targetChain, address(governor2));
        governor1.setDuration(1000);
        vm.selectFork(targetFork);
        governor2.addSupportedContract(sourceChain, address(governor1));
        governor2.setDuration(2000);
        vm.selectFork(sourceFork);
    }

    function _createAProposalOnSourceChain() internal {
        uint256 cost = governor1.quoteBroadcastingFees();
        testTargets1.push(address(1));
        testValues1.push(1 ether);
        testCalldatas1.push(bytes(""));
        string memory description = "Proposal 1";
        vm.recordLogs();
        governor1.createProposal{value: cost}(
            testTargets1,
            testValues1,
            testCalldatas1,
            description
        );
        performDelivery();
        vm.selectFork(targetFork);
        require(governor2.totalEstimatedActiveBaseChainProposal() == 0);
        require(
            governor2.totalEstimatedActiveCrossChainProposal(sourceChain) == 1
        );
        vm.selectFork(sourceFork);
    }

    enum VoteTypes {
        ForVotes,
        AgainstVotes,
        AbstrainVotes
    }

    function _setupTokens() public {
        token1.mint(address(100), 100 ether);
        token1.mint(address(101), 100 ether);
        token1.mint(address(102), 100 ether);
        token1.mint(address(103), 100 ether);
        vm.selectFork(targetFork);
        token2.mint(address(100), 50 ether);
        token2.mint(address(101), 50 ether);
        token2.mint(address(102), 50 ether);
        token2.mint(address(103), 50 ether);
        vm.selectFork(sourceFork);
    }

    function _castVotes() public {
        vm.startPrank(address(100));
        token1.approve(address(governor1), 100 ether);
        governor1.stake(10 ether);
        governor1.voteOnBaseProposal(0, IGovernor.VoteTypes.ForVotes);
        governor1.stake(10 ether);
        governor1.voteOnBaseProposal(0, IGovernor.VoteTypes.ForVotes);
        governor1.unstake(5 ether);
        (
            uint256 totalVotes,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstrainVotes
        ) = governor1.hasVotedOnBaseProposal(0, address(100));
        console.log(totalVotes);
        vm.stopPrank();

        vm.startPrank(address(101));
        token1.approve(address(governor1), 100 ether);
        governor1.stake(10 ether);
        governor1.voteOnBaseProposal(0, IGovernor.VoteTypes.ForVotes);
        governor1.stake(10 ether);
        governor1.voteOnBaseProposal(0, IGovernor.VoteTypes.ForVotes);
        governor1.unstake(5 ether);
        (totalVotes, forVotes, againstVotes, abstrainVotes) = governor1
            .hasVotedOnBaseProposal(0, address(100));
        console.log(totalVotes);
        vm.stopPrank();
    }

    function _castCrossChainVotes() public {
        vm.selectFork(targetFork);
        vm.startPrank(address(102));
        token2.approve(address(governor2), 100 ether);
        governor2.stake(10 ether);
        governor2.voteOnCrossChainProposal(
            sourceChain,
            0,
            IGovernor.VoteTypes.AgainstVotes
        );
        vm.stopPrank();
        vm.startPrank(address(103));
        token2.approve(address(governor2), 100 ether);
        governor2.stake(5 ether);
        governor2.voteOnCrossChainProposal(
            sourceChain,
            0,
            IGovernor.VoteTypes.AbstrainVotes
        );
        vm.stopPrank();
        vm.selectFork(sourceFork);
    }

    function _countTheProposalVotes() public {
        vm.warp(block.timestamp + 2500);
        uint256 cost = governor1.quoteBroadcastingFees();
        vm.recordLogs();
        governor1.countVotes{value: cost}(0);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        vm.recordLogs();
        performDelivery(logs);
        vm.selectFork(targetFork);
        performDelivery();
        console.log(address(governor2).balance);
        vm.selectFork(sourceFork);
    }

    function _fundTheGovernanceContracts() public {
        payable(address(governor1)).call{value: 1 ether}("");
        vm.selectFork(targetFork);
        payable(address(governor2)).call{value: 1 ether}("");
        vm.selectFork(sourceFork);
    }

    function executeTheProposal() public {
        governor1.executeProposal(0);
    }

    function testCreateProposalOnSourceChain() public {
        _connectAllContracts();
        _createAProposalOnSourceChain();
        _setupTokens();
        _castVotes();
        _castCrossChainVotes();
        _fundTheGovernanceContracts();
        _countTheProposalVotes();
    }
}
