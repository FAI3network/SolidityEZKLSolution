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
    error URINotProvided();

    /* Events */
    event ModelRegistered(IVerifier indexed verifier, address indexed owner);
    event ModelDeleted(IVerifier indexed verifier, address indexed owner);
    event InferenceVerified(
        IVerifier indexed verifier,
        bytes indexed proof,
        uint256[] instances,
        bool[3][] relVariables,
        address indexed prover
    );
    event MetricsRun(
        IVerifier indexed verifier,
        int256[] metrics,
        bytes32 indexed nullifier
    );

    /**
     * @dev Register a new model
     * @param verifier: verifier contract, used as identifier for the model
     * @dev Emits a {ModelRegistered} event
     */
    function registerModel(IVerifier verifier, string memory) external;

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
        uint256[] memory instances,
        bool[3][] memory relVariables
    ) external returns (bytes32 nullifier);

    /**
     * @dev Run fairness metrics on an inference
     * @param nullifier nullifier of the inference
     * @notice The inference must not have been checked before
     */
    function runFairness(
        bytes32 nullifier
    ) external returns (int256[] memory metrics);

    /**
     * @dev Get the model information
     * @param verifier address of verifier contract
     * @return owner model owner
     * @return modelURI model URI
     */
    function getModel(
        address verifier
    ) external view returns (address owner, string memory modelURI);

    /**
     * @dev Get the model URI
     * @param verifier address of verifier contract
     * @return modelURI model URI
     */
    function getModelURI(
        address verifier
    ) external view returns (string memory modelURI);

    /**
     * @dev Get the inference information
     * @param nullifier nullifier of the inference
     * @return verifier contract verifier of the inference
     * @return relVariables relevant variables of the inference
     * @return prover prover of the inference
     */
    function getInference(
        bytes32 nullifier
    )
        external
        view
        returns (
            IVerifier verifier,
            bool[3][] memory relVariables,
            address prover
        );
}
