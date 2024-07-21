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
    error InvalidLength();

    /* Events */
    event ModelRegistered(
        IVerifier indexed verifier,
        address indexed owner,
        string modelURI
    );
    event ModelDeleted(IVerifier indexed verifier, address indexed owner);
    event InferenceVerified(
        IVerifier indexed verifier,
        bytes indexed proof,
        uint256[] instances,
        address indexed prover
    );
    event MetricsRun(address indexed verifier, int256[] metrics);

    /**
     * @dev Register a new model
     * @param verifier: verifier contract, used as identifier for the model
     * @param modelURI: URI of the model (link)
     * @param priviligedIndex: index of the priviliged variable (input)
     * @param predictedIndex: index of the predicted variable (output)
     * @dev Emits a {ModelRegistered} event
     */
    function registerModel(
        IVerifier verifier,
        string memory modelURI,
        uint256 priviligedIndex,
        uint256 predictedIndex
    ) external;

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
     * @param target target value (expected output)
     * @param privId priviliged variable index
     * @notice The nullifier is a unique identifier for the inference and is used to check if the inference has been run
     * @return nullifier nullifier of the inference
     */
    function verifyInference(
        IVerifier verifier,
        bytes memory proof,
        uint256[] memory instances,
        uint256 target,
        uint256 privId
    ) external returns (bytes32 nullifier);

    /**
     * @dev Run fairness metrics on an inference
     * @param verifier verifier contract
     * @notice The model must be registered before running metrics
     * @return metrics fairness metrics (1e18)
     */
    function runFairness(
        IVerifier verifier
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
     * @dev Get Convolution Matrix of the priviliged group
     * @param verifier address of verifier contract
     */
    function getPriviligedData(
        address verifier
    ) external view returns (uint tP, uint fP, uint tN, uint fN);

    /**
     * @dev Get Convolution Matrix of the unpriviliged group
     * @param verifier address of verifier contract
     */
    function getUnpriviligedData(
        address verifier
    ) external view returns (uint tP, uint fP, uint tN, uint fN);
}
