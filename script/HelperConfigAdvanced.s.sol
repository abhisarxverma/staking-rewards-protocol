// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol"; 

contract HelperConfig is Script {
    struct NetworkConfig {
        address stakingToken;
        address rewardToken;
        uint256 rewardsDuration;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            stakingToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, // Example Sepolia Link Token
            rewardToken: 0x94a3429943CD46156B82c2A7697475f80b27DfBA,  // Example Sepolia Wrapped BTC
            rewardsDuration: 7 days
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.stakingToken != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockERC20 mockStaking = new MockERC20("Mock Staking", "MSTK");
        MockERC20 mockReward = new MockERC20("Mock Reward", "MRWD");
        vm.stopBroadcast();

        return NetworkConfig({
            stakingToken: address(mockStaking),
            rewardToken: address(mockReward),
            rewardsDuration: 7 days
        });
    }
}
