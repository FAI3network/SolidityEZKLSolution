// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IVerifier {
    function verifyProof(
        bytes calldata proof,
        uint256[] calldata instances
    ) external view returns (bool);
}
