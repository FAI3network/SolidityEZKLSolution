// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IVerifier} from "./IVerifier.sol";

interface ILeaderboard {
    /* Errors */
    error ModelAlreadyRegistered();
    error ModelNotRegistered();
    error InferenceAlreadyVerified();
    error InvalidProof();
    error NotProver();
    error InferenceAlreadyChecked();

    /* Events */
    event ModelRegistered(uint256 modelId, IVerifier verifier, address owner);
    event InferenceVerified(
        uint256 modelId,
        bytes proof,
        uint256[] instances,
        address prover
    );
    event MetricsRun(uint256 modelId, uint256[] metrics);

    /**
     * @dev Register a new model
     * @param verifier: verifier contract, used as identifier for the model
     * @dev Emits a {ModelRegistered} event
     */
    function registerModel(IVerifier verifier) external;

    /**
     * @dev Verify an inference
     * @param verifier verifier contract
     * @param proof proof of the inference
     * @param instances output instances
     * @notice The nullifier is a unique identifier for the inference and is used to check if the inference has been run
     * @return nullifier nullifier of the inference
     */
    function verifyInference(
        IVerifier verifier,
        bytes memory proof,
        uint256[] memory instances
    ) external returns (bytes32 nullifier);

    /**
     * @dev Run fairness metrics on an inference
     * @param nullifier nullifier of the inference
     * @notice The inference must not have been checked before
     */
    function runFairness(bytes32 nullifier) external;

    /**
     * @dev Get the model information
     * @param verifier verifier contract
     * @return modelId model id
     * @return owner model owner
     */
    function getModel(
        address verifier
    ) external view returns (uint256 modelId, address owner);
}
