// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";
import { MinimalAccount } from "src/ethereum/MinimalAccount.sol";

import { DeployMinimal } from "script/DeployMinimal.s.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccountTest is Test {
    HelperConfig private helperConfig;
    MinimalAccount private minimalAccount;
    ERC20Mock private usdc = new ERC20Mock();

    uint256 private constant AMOUNT = 1e18;

    function setUp() public {
        DeployMinimal deployMinimal = new DeployMinimal();
        (helperConfig, minimalAccount) = deployMinimal.deployMinimalAccount();
    }

    // USDC mint
    // msg.sender -> MinimalAccount
    // approve some amount
    // should come from the entrypoint
    function testUserCanExecuteCommands() public {
        // Arrange
        assertEq(
        usdc.balanceOf(address(minimalAccount)), 0
        );

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(
                ERC20Mock.mint.selector,
                address(minimalAccount),
                AMOUNT
            );

        // Act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);

        // Assert
        assertEq(
            usdc.balanceOf(address(minimalAccount)), AMOUNT
        );
    }
}
