// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {StakingRewardsAdvanced} from "../src/StakingRewardsAdvanced.sol";
import {HelperConfig} from "./HelperConfigAdvanced.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployStakingRewards is Script {
    function run() external returns (StakingRewardsAdvanced, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            address stakingToken,
            address rewardToken,
            uint256 rewardsDuration
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        StakingRewardsAdvanced stakingContract = new StakingRewardsAdvanced(
            IERC20(stakingToken),
            IERC20(rewardToken),
            rewardsDuration
        );
        vm.stopBroadcast();

        return (stakingContract, helperConfig);
    }
}
