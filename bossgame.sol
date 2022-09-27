// SPDX-License-Identifier: UNLICENSED

// File: @openzeppelin/contracts/utils/Context.sol

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.9;

contract bossGame is Ownable {
    address[] players;
    bool contributionPeriodOn;

    uint256 randNonce = 0;
    uint256 playersCount;

    uint256 private startTime;

    uint256 private _minDeposit = 0.01 ether;
    uint256 private _maxDeposit = 0.5 ether;

    uint256 private victoryReward;
    uint256 private totalcontributed = 0;

    mapping(address => uint256) playerDeposit;
    mapping(address => bool) isPlayer;

    event ContributionPeriodFinished(bool state);
    event fightWon(bool state);

    // public
    function _Deposit() public payable {
        require(contributionPeriodOn, "Can't deposit now");

        require(
            msg.value >= _minDeposit &&
                playerDeposit[msg.sender] + msg.value <= _maxDeposit,
            "Unsupported deposit amount"
        );
        if ((block.timestamp - startTime) < 120) {
            if (!isPlayer[msg.sender]) {
                isPlayer[msg.sender] = true;
                players.push(msg.sender);
                playersCount++;
            }
            playerDeposit[msg.sender] += msg.value;
        } else {
            contributionPeriodOn = false;
            emit ContributionPeriodFinished(contributionPeriodOn);
        }
    }

    // owner
    function startContributionPeriod() public onlyOwner {
        contributionPeriodOn = true;
        startTime = block.timestamp;
    }

    // internal

    function startFight() internal {
        require(contributionPeriodOn == false && totalcontributed > 0);
        for (uint256 i = 0; i < players.length; i++) {
            address p = players[i];
            totalcontributed += playerDeposit[p];
        }
        //to be changed
        uint bossHp = totalcontributed ** (1 + (randMod() / 10));
        uint totalDmg = totalcontributed ** (1 + (randMod() / 10));
        uint amountEarned = address(this).balance / playersCount;
        if (totalDmg >= bossHp){
            emit fightWon(true);
         for (uint256 i = 0; i < players.length; i++) {
            payable(players[i]).transfer(amountEarned);
        }
        } else {
            emit fightWon(false);
            payable(players[i]).transfer(totalcontributed);
        }

    }
    

    function randMod() internal returns (uint256) {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % 1;
    }

    // views
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getPlayerInfo(address playerAddress)
        public
        view
        returns (bool, uint256)
    {
        return (isPlayer[playerAddress], playerDeposit[playerAddress]);
    }

    receive() external payable {}

    fallback() external payable {}
}
