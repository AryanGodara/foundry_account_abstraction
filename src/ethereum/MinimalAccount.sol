// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAccount } from "@account-abstraction/contracts/interfaces/IAccount.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS } from "@account-abstraction/contracts/core/Helpers.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Entrypoint -> this contract
contract MinimalAccount is IAccount, Ownable {
    ///////////////////////////
    // ERRORS
    ///////////////////////////
    error MinimalAccount_NotFromEntryPoint();
    error MinimalAccount_NotFromEntryPointOrOwner();
    error MinimalAccount_CallFailed(bytes);

    ///////////////////////////
    // STATE
    ///////////////////////////
    IEntryPoint internal immutable i_entryPoint;

    ///////////////////////////
    // MODIFIERS
    ///////////////////////////
    modifier requireFromEntryPoint() {
        if ( msg.sender != address(i_entryPoint) ) {
            revert(MinimalAccount_NotFromEntryPoint());
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if ( msg.sender != address(i_entryPoint) || msg.sender != owner() ) {
            revert(MinimalAccount_NotFromEntryPointOrOwner());
        }
        _;
    }

    ///////////////////////////
    // CONSTRUCTOR
    ///////////////////////////
    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    ///////////////////////////
    // EXTERNAL FUNCTIONS
    ///////////////////////////
    function execute(
        address dest,
        uint256 value,
        bytes calldata funcData
    )
    external
    requireFromEntryPointOrOwner {
        (bool success, bytes memory result) =
            dest.call({value: value})(funcData);

        if (!success) {
            revert(MinimalAccount_CallFailed(result));
        }
    }

    receive() external payable {}

    // A signature is valid , if it's the MinimalAccount owner
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
    external
    requireFromEntryPoint
    returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }

    ///////////////////////////
    // INTERNAL FUNCTIONS
    ///////////////////////////
    // EIP-191 version of signed hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
    internal view
    returns (uint256 validationData) {
        bytes32 ethSignedMessageHash =
                            MessageHashUtils.toEthSignedMessageHash(userOpHash);

        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);

        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }

        return SIG_VALIDATION_SUCCESS;
    }

    // Pay the missing funds
    function _payPrefund(uint256 missingAccountFunds) internal {
        if ( missingAccountFunds != 0 ) {
            (bool success, ) = payable(msg.sender)
                .call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }

    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}