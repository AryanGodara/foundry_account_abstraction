// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script } from "forge-std/Script.sol";

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { PackedUserOperation } from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import {HelperConfig} from "./HelperConfig.s.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function run() public {}

    function generatePackedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config
    ) public view
    returns (PackedUserOperation memory) {
        uint256 nonce = vm.getNonce(config.account);

        // 1. Generate the unsigned data
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(
            callData, config.account, nonce
        );

        // 2. Get the userOpHash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // 3. Sign the userOp
        uint8 v;
        bytes32 r;
        bytes32 s;

        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        if ( block.chainid == 31337 ) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }

        userOp.signature = abi.encodePacked(r, s, v);

        return userOp;
    }

    function _generateUnsignedUserOperation(
        bytes memory callData,
        address sender,
        uint256 nonce
    ) internal pure
    returns (PackedUserOperation memory) {
        uint128 verificationGasLimit = 16_777_216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: "",
            callData: callData,
            accountGasLimits: bytes32( // Concatenate the two gas limits using bit manipulation
                (uint256(verificationGasLimit) << 128) | uint256(callGasLimit)
            ),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(
                (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
            ),
            paymasterAndData: "",
            signature: ""
        });
    }
}
