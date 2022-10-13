// SPDX-License-Identifier: UNLICENSED

// File: @openzeppelin/contracts/utils/Context.sol

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.9;

contract bossGame is Ownable {
    address[] players;

    struct BossFight {
        uint32 round_id;
        uint32 startTime;
        uint victoryReward;
        uint totalcontributed;
        bool bossDefeated;
    }

    uint256 public playersCount;
    uint256 public MAX_PLAYERS = 30;

    uint256 private randNonce = 0;
    uint256 private count = 0;
    uint256 private _minDeposit = 0.01 ether;
    uint256 private _maxDeposit = 0.5 ether;

    bool public contributionPeriodOn;

    mapping(uint256 => BossFight) public bossFights;

    mapping(uint256 => mapping(address => uint256)) public playerDeposit;
    mapping(uint256 => mapping(address => bool)) public isPlayer;
    mapping(address => uint256) public lastRound;

    event ContributionPeriodStarted(uint256 count, uint32 startTime);
    event PlayerDeposited(uint256 count, uint256 amount, address player);
    event ContributionPeriodFinished(bool state);
    event fightWon(bool state);

    // public
    function _Deposit() public payable {
        require(contributionPeriodOn, "Can't deposit now");
        require(MAX_PLAYERS >= playersCount, "Max players amount reached");
        require(
            msg.value >= _minDeposit &&
                playerDeposit[count][msg.sender] + msg.value <= _maxDeposit,
            "Unsupported deposit amount"
        );
        if ((block.timestamp - startTime) < 3600) {
            if (!isPlayer[count][msg.sender]) {
                isPlayer[count][msg.sender] = true;
                players.push(msg.sender);
                playersCount++;
            }
            playerDeposit[count][msg.sender] += msg.value;
            emit PlayerDeposited(count, msg.sender, msg.value);
        } else {
            contributionPeriodOn = false;
            emit ContributionPeriodFinished(true);
            startFight();
        }
    }

    function claimWin() public {
        BossFight storage bossFight = bossFights[count];
        require(bossFight.bossDefeated == true, "You lost the round");
        require(lastRound[msg.sender] < bossFight.round_id, "Already claimed");
        lastRound[msg.sender] = bossFight.round_id;
        uint256 amount = calculatePlayerShare(msg.sender);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send rewards");
    }

    // owner
    function startContributionPeriod() public onlyOwner {
        require(contributionPeriodOn == false, "Period already started");
        contributionPeriodOn = true;
        bossFights[count] = BossFight({
            round_id: count,
            startTime: block.timestamp,
            totalcontributed: 0,
            bossDefeated: false,
            victoryReward: 0
        });
        emit ContributionPeriodStarted(count, block.timestamp);
    }

    // internal

    function startFight() internal {
        BossFight storage bossFight = bossFights[count];
        require(contributionPeriodOn == false);
        for (uint256 i = 0; i < players.length; i++) {
            bossFight.totalcontributed += playerDeposit[count][players[i]];
        }
        //to bechanged
        uint256 bossHp = bossFight.totalcontributed**(1 + (randMod() / 10));
        uint256 totalDmg = bossFight.totalcontributed**(1 + (randMod() / 10));
        if (totalDmg >= bossHp) {
            bossDefeated = true;
            emit fightWon(true);
            reset();
        } else {
            //refund (to be changed too)
            bossDefeated = false;
            uint amount =  bossFight.totalcontributed;
            emit fightWon(false);
            for (uint256 i = 0; i < players.length; i++) {
            payable(players[i]).transfer((amount * 100 )/ playerDeposit[count][players[i]]);
        }
            reset();
        }
    }

    function calculatePlayerShare(address playerAddress)
        internal
        returns (uint256)
    {
        return
            (address(this).balance * 100) / playerDeposit[count][playerAddress];
    }

    function reset() internal {
        count += 1;
        contributionPeriodOn = false;
        players = [];
        playersCount = 0;
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
        return (
            isPlayer[count][playerAddress],
            playerDeposit[count][playerAddress]
        );
    }

    receive() external payable {}

    fallback() external payable {}
}
