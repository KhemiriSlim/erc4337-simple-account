// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@account-abstraction/contracts@0.7.0/interfaces/IAccount.sol";
import "@account-abstraction/contracts@0.7.0/interfaces/PackedUserOperation.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SimpleOwnerAccount is IAccount {
    address public immutable owner;
    address public immutable entryPoint;

    error NotEntryPoint();
    error ExecutionFailed();

    constructor(address _owner, address _entryPoint) {
        owner = _owner;
        entryPoint = _entryPoint;
    }

    modifier onlyEntryPoint() {
        if (msg.sender != entryPoint) revert NotEntryPoint();
        _;
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override onlyEntryPoint returns (uint256 validationData) {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(hash, userOp.signature);
        validationData = signer == owner ? 0 : 1;
        if (missingAccountFunds > 0) {
            (bool ok, ) = payable(msg.sender).call{value: missingAccountFunds}("");
            (ok); 
        }
    }
    function execute(address target, uint256 value, bytes calldata data)
        external
        onlyEntryPoint
    {
        (bool success, ) = target.call{value: value}(data);
        if (!success) revert ExecutionFailed();
    }
    receive() external payable {}
}