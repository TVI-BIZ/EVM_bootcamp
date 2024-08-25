// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/// @title Voting with delegation.

interface IMyToken {
    function getPastVotes(address, uint256) external view returns (uint256);
    function getVotes(address) external view returns (uint256);
}

contract TokenizedBallot {
    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name; // short name (up to 32 bytes)
        uint256 voteCount; // number of accumulated votes
    }

    IMyToken public tokenContract;
    Proposal[] public proposals;
    uint256 public targetBlockNumber;
    mapping(address => uint256) public spentVotePower;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(bytes32[] memory proposalNames, address _tokenContract) {
        tokenContract = IMyToken(_tokenContract);
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    function vote(uint256 proposal, uint256 amount) external {
        //require(proposals[proposal].name != bytes32("Chocolate mint!"));
        //TODO
        //uint256 voteVotingPower = getVotePower(msg.sender);
        //require(senderVotingPower >= amount, "Insuddent voting power");
        spentVotePower[msg.sender] += amount;
        proposals[proposal].voteCount += amount;
    }

    function getVotePower(address voter) public view returns (uint256 votePower_) {
        votePower_ = tokenContract.getPastVotes(voter, targetBlockNumber) - spentVotePower[voter];
        //spentVotePower[voter] = tokenContract.getPastVotes(voter, targetBlockNumber);
    }

    function getVotes(address voter) public view returns (uint256 votes) {
        votes = tokenContract.getVotes(voter);
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
