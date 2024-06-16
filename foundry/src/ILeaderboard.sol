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
    error NotOwner();
    error InferenceAlreadyChecked();
    error InferenceNotExists();

    /* Events */
    event ModelRegistered(IVerifier indexed verifier, address indexed owner);
    event ModelDeleted(IVerifier indexed verifier, address indexed owner);
    event InferenceVerified(
        IVerifier indexed verifier,
        bytes indexed proof,
        uint256[] instances,
        address indexed prover
    );
    event MetricsRun(
        IVerifier indexed verifier,
        uint256[] metrics,
        bytes32 indexed nullifier
    );

    /**
     * @dev Register a new model
     * @param verifier: verifier contract, used as identifier for the model
     * @dev Emits a {ModelRegistered} event
     */
    function registerModel(IVerifier verifier) external;

    /**
     * @dev Delete a model
     * @param verifier verifier contract
     */
    function deleteModel(IVerifier verifier) external;

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
     * @param verifier address of verifier contract
     * @return owner model owner
     */
    function getModel(address verifier) external view returns (address owner);

    /**
     * @dev Get the inference information
     * @param nullifier nullifier of the inference
     * @return verifier contract verifier of the inference
     * @return instances output instances
     * @return prover prover of the inference
     */
    function getInference(
        bytes32 nullifier
    )
        external
        view
        returns (
            IVerifier verifier,
            uint256[] memory instances,
            address prover
        );
}
