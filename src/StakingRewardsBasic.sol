// SPDX-License-Identifier: MIT

pragma solidity ^0.8.34;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingRewardsBasic is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error StakingRewards__AmountCannotBeZero();
    error StakingRewards__InsufficientBalance();
    error StakingRewards__NoRewardsEarned();
    error StakingRewards__ZeroStakedBalanceAndZeroRewardsToClaim();
    error StakingRewards__SenderNotOwner();
    error StakingRewards__RewardRateCannotBeZero();
    error StakingRewards__InsufficientRewardTokens();

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    address owner;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakingTimestamp;
    mapping(address => uint256) public rewards;

    uint256 public totalStaked;
    uint256 public rewardRate;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardFunded(uint256 amount);
    event RewardRateUpdated(uint256 newRate);

    constructor(IERC20 _stakingToken, IERC20 _rewardToken, uint256 _rewardRate) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        rewardRate = _rewardRate;
        owner = msg.sender;
    }

    function stake(uint256 amount) public {
        _updateRewards(msg.sender);

        if (amount == 0) revert StakingRewards__AmountCannotBeZero();

        stakedBalance[msg.sender] += amount;
        totalStaked += amount;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function _updateRewards(address user) internal {
        if (stakedBalance[user] > 0) {
            uint256 stakingDuration = block.timestamp - stakingTimestamp[user];
            rewards[user] += (stakedBalance[user] * stakingDuration * rewardRate) / 1e18;
        }
        stakingTimestamp[user] = block.timestamp;
    }

    function withdraw(uint256 amount) public nonReentrant {
        _updateRewards(msg.sender);

        if (amount > stakedBalance[msg.sender]) {
            revert StakingRewards__InsufficientBalance();
        }

        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;

        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() public nonReentrant {
        _updateRewards(msg.sender);

        if (rewards[msg.sender] == 0) {
            revert StakingRewards__NoRewardsEarned();
        }
        if (rewardToken.balanceOf(address(this)) < rewards[msg.sender]) {
            revert StakingRewards__InsufficientRewardTokens();
        }

        uint256 rewardsToTransfer = rewards[msg.sender];
        rewards[msg.sender] = 0;

        rewardToken.safeTransfer(msg.sender, rewardsToTransfer);

        emit RewardClaimed(msg.sender, rewardsToTransfer);
    }

    function exit() public nonReentrant {
        _updateRewards(msg.sender);

        if (stakedBalance[msg.sender] == 0 && rewards[msg.sender] == 0) {
            revert StakingRewards__ZeroStakedBalanceAndZeroRewardsToClaim();
        }

        if (rewards[msg.sender] > 0) {
            uint256 rewardsToTransfer = rewards[msg.sender];
            rewards[msg.sender] = 0;
            if (rewardToken.balanceOf(address(this)) < rewardsToTransfer) {
                revert StakingRewards__InsufficientRewardTokens();
            }
            rewardToken.safeTransfer(msg.sender, rewardsToTransfer);
        }

        if (stakedBalance[msg.sender] > 0) {
            uint256 balanceToReturn = stakedBalance[msg.sender];
            stakedBalance[msg.sender] = 0;
            stakingToken.safeTransfer(msg.sender, balanceToReturn);
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert StakingRewards__SenderNotOwner();
        }
        _;
    }

    function fundRewards(uint256 amount) public onlyOwner {
        if (amount == 0) {
            revert StakingRewards__AmountCannotBeZero();
        }

        rewardToken.safeTransferFrom(owner, address(this), amount);

        emit RewardFunded(amount);
    }

    function setRewardRate(uint256 newRewardRate) public onlyOwner {
        if (newRewardRate == 0) {
            revert StakingRewards__RewardRateCannotBeZero();
        }
        rewardRate = newRewardRate;

        emit RewardRateUpdated(newRewardRate);
    }

    function earned(address user) public view returns (uint256) {
        uint256 currentRewardDuration = block.timestamp - stakingTimestamp[user];
        return rewards[user] + (stakedBalance[user] * currentRewardDuration * rewardRate) / 1e18;
    }
}
