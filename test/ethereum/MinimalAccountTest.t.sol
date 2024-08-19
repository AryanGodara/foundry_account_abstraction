// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";

import { MinimalAccount } from "src/ethereum/MinimalAccount.sol";

import { DeployMinimal } from "script/DeployMinimal.s.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";
import { SendPackedUserOp, PackedUserOperation } from "script/SendPackedUserOp.s.sol";

import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    HelperConfig private helperConfig;
    MinimalAccount private minimalAccount;
    ERC20Mock private usdc = new ERC20Mock();
    SendPackedUserOp private sendPackedUserOp;

    address private randomUser = makeAddr("randomUser");

    uint256 private constant AMOUNT = 1e18;

    function setUp() public {
        DeployMinimal deployMinimal = new DeployMinimal();
        (helperConfig, minimalAccount) = deployMinimal.deployMinimalAccount();
        sendPackedUserOp = new SendPackedUserOp();
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

    function testNonOwnerCannotExecuteCommands() public {
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

        // Act and Assert
        vm.prank(randomUser);
        vm.expectRevert(MinimalAccount.MinimalAccount_NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(dest, value, functionData);
    }

    function testRecoverSignedOp() public {
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

        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector, dest, value, functionData
        );

        PackedUserOperation memory packedUserOperation =
                        sendPackedUserOp.generatePackedUserOperation(
                executeCallData, helperConfig.getConfig()
            );

        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOperation);

        // Act
        address actualSigner = ECDSA.recover(
            userOpHash.toEthSignedMessageHash(),
            packedUserOperation.signature
        );

        // Assert
        assertEq(actualSigner, minimalAccount.owner());
    }

    function testValidationOfUserOps() public {}
}
