// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script, console2 } from "forge-std/Script.sol";
import { EntryPoint } from "@account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    ///////////////////////////
    // ERRORS
    ///////////////////////////
    error HelperConfig__InvalidChainId();

    ///////////////////////////
    // TYPES
    ///////////////////////////
    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    ///////////////////////////
    // CONSTANTS
    ///////////////////////////
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 public constant LOCAL_CHAIN_ID = 31337; // Anvil
    address public constant BURNER_WALLET = 0x4BC8e81Ad3BE83276837f184138FC96770C14297;
    // address public constant FOUNDRY_DEFAULT_WALLET = address(uint160(uint256(keccak256("foundry default caller"))));
    address public constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    // address public constant ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    ///////////////////////////
    // STATE
    ///////////////////////////
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
            return getOrCreateAnvilEthConfig();
        }
        else if (networkConfigs[chainId].account == address(0)) {
            revert HelperConfig__InvalidChainId();
        }

        return networkConfigs[chainId];
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            account: BURNER_WALLET
        });
    }

    function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: address(0),
            account: BURNER_WALLET
        });
    }
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }

        //TODO Deploy a mock EntryPoint contract...
        console2.log("Deploying mocks...");

        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entryPoint: address(entryPoint),
            account: ANVIL_DEFAULT_ACCOUNT
        });

        return localNetworkConfig;
    }

    function run() public {
    }
}