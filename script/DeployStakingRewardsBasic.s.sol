// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {StakingRewardsBasic} from "../src/StakingRewardsBasic.sol";
import {HelperConfig} from "./HelperConfigBasic.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployStakingRewards is Script {
    function run() external returns (StakingRewardsBasic, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            address stakingToken,
            address rewardToken,
            uint256 rewardRate
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        StakingRewardsBasic stakingContract = new StakingRewardsBasic(
            IERC20(stakingToken),
            IERC20(rewardToken),
            rewardRate
        );
        vm.stopBroadcast();

        return (stakingContract, helperConfig);
    }
}
