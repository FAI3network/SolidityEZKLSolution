// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint256 deployerKey;
        uint256 deployerKey2;
    }

    uint256 public ANVIL_PRIVATE_KEY_1 =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public ANVIL_PRIVATE_KEY_2 =
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    constructor() {
        if (block.chainid == 11_155_111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig()
        public
        view
        returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            deployerKey: vm.envUint("DEPLOYER_PRIVATE_KEY"),
            deployerKey2: vm.envUint("DEPLOYER_PRIVATE_KEY_2")
        });
    }

    function getOrCreateAnvilEthConfig()
        public
        view
        returns (NetworkConfig memory anvilNetworkConfig)
    {
        anvilNetworkConfig = NetworkConfig({
            deployerKey: ANVIL_PRIVATE_KEY_1,
            deployerKey2: ANVIL_PRIVATE_KEY_2
        });
    }
}
