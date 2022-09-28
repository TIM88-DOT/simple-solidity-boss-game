// SPDX-License-Identifier: UNLICENSED

// File: @openzeppelin/contracts/utils/Context.sol

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.9;

contract bossGame is Ownable {

    address[] players;
    bool contributionPeriodOn;

    uint256 public randNonce = 0;
    uint256 public playersCount;
    uint256 public MAX_PLAYERS = 30;
    uint256 public cycling_round;

    uint256 private startTime;
    uint256 private _minDeposit = 0.01 ether;
    uint256 private _maxDeposit = 0.5 ether;
    uint256 private _victoryReward;
    uint256 private _totalcontributed = 0;

    mapping(address => uint256) playerDeposit;
    mapping(address => bool) isPlayer;

    event ContributionPeriodFinished(bool state);
    event fightWon(bool state);

    // public
    function _Deposit() public payable {
        require(contributionPeriodOn, "Can't deposit now");
        require(MAX_PLAYERS >= playersCount, "Max players amount reached");
        require(msg.value >= _minDeposit && playerDeposit[msg.sender] + msg.value <= _maxDeposit, "Unsupported deposit amount"
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
            startFight();
        }
    }

      function claimReward() public {
        require(lastWithdrawCycle[_msgSender()] < cycling_round, "Already Claimed");
        lastWithdrawCycle[_msgSender()] = cycling_round;
        uint256 amount = calculatePlayerShare(msg.sender);
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Failed to send rewards");
    }


    // owner
    function startContributionPeriod() public onlyOwner {
        contributionPeriodOn = true;
        startTime = block.timestamp;
    }

    // internal

    function startFight() internal {
        require(contributionPeriodOn == false);
        for (uint256 i = 0; i < players.length; i++) {
            address p = players[i];
            _totalcontributed += playerDeposit[p];
        }
        //to bechanged
        uint bossHp = _totalcontributed ** (1 + (randMod() / 10));
        uint totalDmg = _totalcontributed ** (1 + (randMod() / 10));
        if (totalDmg >= bossHp){
            emit fightWon(true);
        uint amountEarned = calculatePlayerShare();
        for (uint256 i = 0; i < players.length; i++) {
            payable(players[i]).transfer(amountEarned);
        }
        } else {
            //refund
            emit fightWon(false);
            payable(players[i]).transfer(_totalcontributed);
        }

    }

    function calculatePlayerShare(address playerAddress) internal returns(uint256) {
        return (address(this).balance * 100) / playerDeposit[playerAddress];
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

    function getPlayerInfo(address playerAddress)public view returns (bool, uint256)
    {
        return (isPlayer[playerAddress], playerDeposit[playerAddress]);
    }


    receive() external payable {}

    fallback() external payable {}
}
