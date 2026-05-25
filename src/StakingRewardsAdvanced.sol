// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StakingRewardsAdvanced
 * @author Abhisar verma
 * @notice A professional, highly secure staking rewards contract
 */
contract StakingRewardsAdvanced is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /* //////////////////////////////////////////////////////////////
                                 ERRORS
    ////////////////////////////////////////////////////////////// */
    error StakingRewards__AmountCannotBeZero();
    error StakingRewards__InsufficientBalance();
    error StakingRewards__NoRewardsEarned();
    error StakingRewards__RewardPeriodStillActive();
    error StakingRewards__InsufficientRewardBalance();
    error StakingRewards__InvalidAddress();
    error StakingRewards__RewardDurationCannotBeZero();
    error StakingRewards__NotAContractAddress();
    error StakingRewards__InvalidTokenAddress();

    /* //////////////////////////////////////////////////////////////
                             STORAGE VARIABLES
    ////////////////////////////////////////////////////////////// */
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public periodFinish;

    uint256 public totalStaked;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    /* //////////////////////////////////////////////////////////////
                                 EVENTS
    ////////////////////////////////////////////////////////////// */
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 duration);

    /* //////////////////////////////////////////////////////////////
                               MODIFIERS
    ////////////////////////////////////////////////////////////// */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* //////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */
    constructor(IERC20 _stakingToken, IERC20 _rewardToken, uint256 _rewardsDuration) Ownable(msg.sender) {
        if (address(_stakingToken) == address(0)) revert StakingRewards__InvalidAddress();
        if (address(_rewardToken) == address(0)) revert StakingRewards__InvalidAddress();
        if (_rewardsDuration == 0) revert StakingRewards__RewardDurationCannotBeZero();

        _validateERC20(_stakingToken);
        _validateERC20(_rewardToken);

        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        rewardsDuration = _rewardsDuration;
    }

    /* //////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    ////////////////////////////////////////////////////////////// */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp > periodFinish ? periodFinish : block.timestamp;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalStaked;
    }

    function earned(address account) public view returns (uint256) {
        return (balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }

    /* //////////////////////////////////////////////////////////////
                          EXTERNAL MUTATIVE FUNCTIONS
    ////////////////////////////////////////////////////////////// */

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert StakingRewards__AmountCannotBeZero();
        _stake(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert StakingRewards__AmountCannotBeZero();
        _withdraw(msg.sender, amount);
    }

    function getReward() external nonReentrant updateReward(msg.sender) {
        _getReward(msg.sender);
    }

    /**
     * @notice Exits the contract by withdrawing all stakes and claiming rewards.
     * @dev Drastically saves gas by applying the modifier exactly ONCE.
     */
    function exit() external nonReentrant updateReward(msg.sender) {
        uint256 balance = balanceOf[msg.sender];
        if (balance > 0) {
            _withdraw(msg.sender, balance);
        }
        _getReward(msg.sender);
    }

    /* //////////////////////////////////////////////////////////////
                          INTERNAL CORE LOGIC
    ////////////////////////////////////////////////////////////// */

    function _stake(address account, uint256 amount) internal {
        balanceOf[account] += amount;
        totalStaked += amount;
        stakingToken.safeTransferFrom(account, address(this), amount);
        emit Staked(account, amount);
    }

    function _withdraw(address account, uint256 amount) internal {
        if (amount > balanceOf[account]) revert StakingRewards__InsufficientBalance();
        balanceOf[account] -= amount;
        totalStaked -= amount;
        stakingToken.safeTransfer(account, amount);
        emit Withdrawn(account, amount);
    }

    function _getReward(address account) internal {
        uint256 rewardsToTransfer = rewards[account];
        if (rewardsToTransfer > 0) {
            rewards[account] = 0;
            rewardToken.safeTransfer(account, rewardsToTransfer);
            emit RewardPaid(account, rewardsToTransfer);
        }
    }

    /* //////////////////////////////////////////////////////////////
                             OWNER FUNCTIONS
    ////////////////////////////////////////////////////////////// */
    function setRewardsDuration(uint256 duration) external onlyOwner {
        if (duration == 0) revert StakingRewards__RewardDurationCannotBeZero();
        if (block.timestamp <= periodFinish) revert StakingRewards__RewardPeriodStillActive();

        rewardsDuration = duration;
        emit RewardsDurationUpdated(duration);
    }

    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        if (reward == 0) revert StakingRewards__AmountCannotBeZero();

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftoverRewards = remaining * rewardRate;
            rewardRate = (reward + leftoverRewards) / rewardsDuration;
        }

        rewardToken.safeTransferFrom(msg.sender, address(this), reward);

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardAdded(reward);
    }

    /* //////////////////////////////////////////////////////////////
                             INTERNAL HELPER FUNCTIONS
    ////////////////////////////////////////////////////////////// */
    function _validateERC20(address token) internal view {
        uint256 size;
        assembly {
            size := extcodesize(token)
        }
        if (size == 0) revert StakingRewards__NotAContractAddress();

        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("totalSupply()")
        );
        
        if (!success || data.length == 0) {
            revert StakingRewards__InvalidTokenAddress();
        }
    }
}
