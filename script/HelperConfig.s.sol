// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";

contract HelperConfig is Script {
    ///////////////////////////
    // ERRORS
    ///////////////////////////
    error HelperConfig__InvalidChainId();

    ///////////////////////////
    // CONSTANTS
    ///////////////////////////
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    ///////////////////////////
    // STATE
    ///////////////////////////
    struct NetworkConfig {
        address entryPoint;
    }

    NetworkConfig public localNetworkConfig;

    mapping(uint256 => NetworkConfig) public networkConfigs;

    ///////////////////////////
    // CONSTRUCTOR
    ///////////////////////////
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncSepoliaConfig();
    }

    ///////////////////////////
    // GETTERS
    ///////////////////////////

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return localNetworkConfig;
        }
        else if (networkConfigs[chainId].entryPoint == address(0)) {
            revert HelperConfig__InvalidChainId();
        }

        return networkConfigs[chainId];
    }

    function getEthSepoliaConfig() public returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
        });
    }

    function getZkSyncSepoliaConfig() public returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: address(0)
        });
    }
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.entryPoint != address(0)) {
            return localNetworkConfig;
        }

        //TODO Deploy a mock EntryPoint contract...
    }

    function run() public {
    }
}