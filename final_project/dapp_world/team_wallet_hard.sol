// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TeamWallet {
    address owner;
    uint256 credit_pool;
    uint256 tx_counter = 1;

    bool set_flag;
    bool member_flag;

    address[] winning_team_array;
    Request[] request_array;
    address[] spend_vote;
    //mapping(uint=>string) txn_status;
    mapping(string => uint256) txn_stats;

    struct Request {
        address requester;
        uint256 request_amount;
        uint256 tx_number;
        uint256 vote_counter;
        uint256 reject_counter;
        string status;
        mapping(address => bool) vote_owner;
    }

    struct Approuve {
        address aprouver;
        bool voted;
    }

    constructor() {
        owner = msg.sender;
    }

    //For setting up the wallet
    function setWallet(address[] memory members, uint256 credtis) public {
        require(msg.sender == owner, "Not owner");
        require(members.length > 0, "No any members");
        require(credtis > 0, "Not enough credit");
        require(set_flag == false, "Already set");
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == owner) {
                revert("Owner can't be team member");
            }
        }
        winning_team_array = members;
        credit_pool = credtis;
        set_flag = true;
    }

    //For spending amount from the wallet
    function spend(uint256 amount) public {
        require(amount > 0, "Not enough credit");
        member_flag = false;
        for (uint256 i = 0; i < winning_team_array.length; i++) {
            if (winning_team_array[i] == msg.sender) {
                member_flag = true;
            }
        }
        if (member_flag == false) {
            revert("Not a team member");
        }

        Request storage new_request = request_array.push();
        new_request.requester = msg.sender;
        new_request.request_amount = amount;
        new_request.tx_number = tx_counter;
        new_request.vote_counter = 0;
        new_request.reject_counter = 0;
        if (amount > credit_pool) {
            new_request.status = "failed";
            txn_stats["failed"] += 1;
        } else if ((winning_team_array.length == 1) && (amount < credit_pool)) {
            new_request.status = "debited";
            txn_stats["debitedCount"] += 1;
            credit_pool -= amount;
        } else if ((winning_team_array.length == 1) && (amount > credit_pool)) {
            new_request.status = "failed";
            txn_stats["failed"] += 1;
        } else {
            new_request.status = "pending";
            txn_stats["pendingCount"] += 1;
        }
        new_request.vote_owner[address(0)] = false;
        //request_array.push(new_request);
        tx_counter++;
    }

    //For approving a transaction request
    function approve(uint256 n) public {
        require(n < tx_counter, "No transaction");
        require(n > 0, "No zero transaction");
        member_flag = false;
        for (uint256 i = 0; i < winning_team_array.length; i++) {
            if (winning_team_array[i] == msg.sender) {
                member_flag = true;
            }
        }
        if (member_flag == false) {
            revert("Not a team member");
        }

        for (uint256 i = 0; i < request_array.length; i++) {
            if (request_array[i].tx_number == n) {
                require(request_array[i].vote_owner[msg.sender] != true, "Already vote");
                require(request_array[i].requester != msg.sender, "Can't wote own request");

                request_array[i].vote_counter += 1;
                request_array[i].vote_owner[msg.sender] = true;

                if (winning_team_array.length != 3) {
                    if (request_array[i].vote_counter > (winning_team_array.length * 3) / 10) {
                        request_array[i].status = "debited";
                        txn_stats["debitedCount"] += 1;
                        txn_stats["pendingCount"] -= 1;
                        credit_pool -= request_array[i].request_amount;
                    }
                    spend_vote.push(msg.sender);
                } else {
                    require(request_array[i].request_amount < credit_pool, "Too Big amount");
                    if (request_array[i].vote_counter > (winning_team_array.length * 6) / 10) {
                        request_array[i].status = "debited";
                        txn_stats["debitedCount"] += 1;
                        txn_stats["pendingCount"] -= 1;
                        credit_pool -= request_array[i].request_amount;
                    }
                    spend_vote.push(msg.sender);
                }
            }
        }
    }
    //For rejecting a transaction request

    function reject(uint256 n) public {
        require(n > 0, "No 0 transaction");
        require(n < tx_counter, "No transaction");

        member_flag = false;
        for (uint256 i = 0; i < winning_team_array.length; i++) {
            if (winning_team_array[i] == msg.sender) {
                member_flag = true;
            }
        }
        if (member_flag == false) {
            revert("Not a team member");
        }
        for (uint256 i = 0; i < request_array.length; i++) {
            if (request_array[i].tx_number == n) {
                require(
                    keccak256(abi.encodePacked((request_array[i].status))) != (keccak256(abi.encodePacked("failed"))),
                    "Failed already"
                );
                require(request_array[i].requester != msg.sender, "Can't reject own transaction");
                require(request_array[i].vote_owner[msg.sender] == false, "Already reject this");

                request_array[i].vote_owner[msg.sender] = true;
                request_array[i].reject_counter += 1;

                if (request_array[i].reject_counter > (winning_team_array.length * 3) / 10) {
                    request_array[i].status = "failed";
                    txn_stats["failed"] += 1;
                    txn_stats["pendingCount"] -= 1;
                    //credit_pool -= request_array[i].request_amount;
                }
            }
        }
    }

    //For checking remaing credits in the wallet
    function credits() public returns (uint256) {
        member_flag = false;
        for (uint256 i = 0; i < winning_team_array.length; i++) {
            if (winning_team_array[i] == msg.sender) {
                member_flag = true;
            }
        }
        if (member_flag == false) {
            revert("Not a team member");
        }
        return credit_pool;
    }

    //For checking nth transaction status
    function viewTransaction(uint256 n) public returns (uint256 amount, string memory status) {
        require(n > 0, "No 0 transaction");
        require(n < tx_counter, "No transaction");

        member_flag = false;
        for (uint256 i = 0; i < winning_team_array.length; i++) {
            if (winning_team_array[i] == msg.sender) {
                member_flag = true;
            }
        }
        if (member_flag == false) {
            revert("Not a team member");
        }

        for (uint256 i = 0; i < request_array.length; i++) {
            if (request_array[i].tx_number == n) {
                return (request_array[i].request_amount, request_array[i].status);
            }
        }
        return (1, "pending");
    }

    //For checking the transaction stats for the wallet
    function transactionStats() public returns (uint256 debitedCount, uint256 pendingCount, uint256 failedCount) {
        member_flag = false;
        for (uint256 i = 0; i < winning_team_array.length; i++) {
            if (winning_team_array[i] == msg.sender) {
                member_flag = true;
            }
        }
        if (member_flag == false) {
            revert("Not a team member");
        }
        return (txn_stats["debitedCount"], txn_stats["pendingCount"], txn_stats["failed"]);
    }
}
