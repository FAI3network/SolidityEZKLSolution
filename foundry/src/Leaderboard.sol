// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVerifier} from "./IVerifier.sol";
import {ILeaderboard} from "./ILeaderboard.sol";

contract Leaderboard is ILeaderboard {
    struct Model {
        address owner;
        string modelURI;
    }
    struct Inference {
        IVerifier verifier;
        uint256[] instances;
        address prover;
        bool checked; // check if the inference has been used to get metrics
    }

    // verifier => model
    mapping(address => Model) public models;
    // nullifier => inference
    mapping(bytes32 => Inference) public inferences;

    constructor() {}

    /* Modifiers */
    modifier isNotRegistered(address verifier) {
        Model memory model = models[verifier];
        if (model.owner != address(0)) {
            revert ModelAlreadyRegistered();
        }
        _;
    }

    modifier isRegistered(address verifier) {
        Model memory model = models[verifier];
        if (model.owner == address(0)) {
            revert ModelNotRegistered();
        }
        _;
    }

    modifier isOwner(address verifier) {
        Model memory model = models[verifier];
        if (model.owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    modifier isNotVerified(bytes32 nullifier) {
        Inference memory inference = inferences[nullifier];
        if (inference.prover != address(0)) {
            revert InferenceAlreadyVerified();
        }
        _;
    }

    modifier inferenceExists(bytes32 nullifier) {
        Inference memory inference = inferences[nullifier];
        if (inference.prover == address(0)) {
            revert InferenceNotExists();
        }
        _;
    }

    modifier isProver(bytes32 nullifier, address prover) {
        Inference memory inference = inferences[nullifier];
        if (inference.prover != prover) {
            revert NotProver();
        }
        _;
    }

    modifier isNotChecked(bytes32 nullifier) {
        Inference memory inference = inferences[nullifier];
        if (inference.checked) {
            revert InferenceAlreadyChecked();
        }
        _;
    }

    /**
     * @dev See {ILeaderboard-registerModel}
     */
    function registerModel(
        IVerifier verifier,
        string memory modelURI
    ) external override isNotRegistered(address(verifier)) {
        if (bytes(modelURI).length == 0) {
            revert URINotProvided();
        }
        models[address(verifier)] = Model({
            owner: msg.sender,
            modelURI: modelURI
        });
        emit ModelRegistered(verifier, msg.sender);
    }

    /**
     * @dev See {ILeaderboard-deleteModel}
     */
    function deleteModel(
        IVerifier verifier
    )
        external
        override
        isRegistered(address(verifier))
        isOwner(address(verifier))
    {
        delete models[address(verifier)];
        emit ModelDeleted(verifier, msg.sender);
    }

    /**
     * @dev See {ILeaderboard-verifyInference}
     */
    function verifyInference(
        IVerifier verifier,
        bytes memory proof,
        uint256[] memory instances
    )
        external
        override
        isRegistered(address(verifier))
        isNotVerified(
            keccak256(abi.encodePacked(address(verifier), proof, instances))
        )
        returns (bytes32)
    {
        bytes32 nullifier = keccak256(
            abi.encodePacked(address(verifier), proof, instances)
        );
        // verify proof
        if (!verifier.verifyProof(proof, instances)) {
            revert InvalidProof();
        }
        inferences[nullifier] = Inference({
            verifier: verifier,
            instances: instances,
            prover: msg.sender,
            checked: false
        });

        emit InferenceVerified(verifier, proof, instances, msg.sender);
        return nullifier;
    }

    /**
     * @dev See {ILeaderboard-runFairness}
     */
    function runFairness(
        bytes32 nullifier
    )
        external
        override
        inferenceExists(nullifier)
        isProver(nullifier, msg.sender)
        isNotChecked(nullifier)
    {
        inferences[nullifier].checked = true;
        Inference memory inference = inferences[nullifier];
        // run metrics
        uint256[] memory metrics = runMetrics(inference.instances);

        emit MetricsRun(inference.verifier, metrics, nullifier);
    }

    /**
     * @dev internal function to run metrics on an inference
     * @param instances output instances
     * @return metrics metrics of the inference
     */
    function runMetrics(
        uint256[] memory instances
    ) internal returns (uint256[] memory) {
        uint256[] memory metrics = new uint256[](3);
        metrics[0] = uint256(1);
        metrics[1] = uint256(1);
        metrics[2] = uint256(1);
        return metrics;
    }

    /**
     * @dev See {ILeaderboard-getModel}
     */
    function getModel(
        address verifier
    ) external view override returns (address owner, string memory modelURI) {
        Model memory model = models[verifier];
        return (model.owner, model.modelURI);
    }

    /**
     * @dev See {ILeaderboard-getInference}
     */
    function getInference(
        bytes32 nullifier
    )
        external
        view
        override
        returns (IVerifier verifier, uint256[] memory instances, address prover)
    {
        Inference memory inference = inferences[nullifier];
        return (inference.verifier, inference.instances, inference.prover);
    }
}
