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
            stakingToken: 0xd67215fD6c0890493F34aF3C5E4231cE98871fCb, // DAI
            rewardToken: 0xE815718D44694ec4637CB775C468d87f6e15B538,  // USDC
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
