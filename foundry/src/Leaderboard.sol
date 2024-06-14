// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVerifier} from "./IVerifier.sol";
import {ILeaderboard} from "./ILeaderboard.sol";

contract Leaderboard is ILeaderboard {
    struct Model {
        uint256 id;
        IVerifier verifier;
        address owner;
    }
    struct Inference {
        uint256 modelId;
        uint256[] instances;
        address prover;
        bool checked; // check if the inference has been used to get metrics
    }

    // verifier => model
    mapping(address => Model) public models;
    // nullifier => inference
    mapping(bytes32 => Inference) public inferences;

    uint256 public s_modelCounter;

    constructor() {
        s_modelCounter = 0;
    }

    /* Modifiers */
    modifier isNotRegistered(address verifier) {
        if (models[verifier].id != 0) {
            revert ModelAlreadyRegistered(models[verifier].id);
        }
        _;
    }

    modifier isRegistered(address verifier) {
        if (models[verifier].verifier == IVerifier(address(0))) {
            revert ModelNotRegistered();
        }
        _;
    }

    modifier isNotVerified(bytes32 nullifier) {
        if (inferences[nullifier].prover != address(0)) {
            revert InferenceAlreadyVerified();
        }
        _;
    }

    modifier inferenceExists(bytes32 nullifier) {
        if (inferences[nullifier].prover == address(0)) {
            revert InferenceNotExists();
        }
        _;
    }

    modifier isProver(Inference memory inference, address prover) {
        if (inference.prover != prover) {
            revert NotProver();
        }
        _;
    }

    modifier isNotChecked(Inference memory inference) {
        if (inference.checked) {
            revert InferenceAlreadyChecked();
        }
        _;
    }

    /**
     * @dev See {ILeaderboard-registerModel}
     */
    function registerModel(
        IVerifier verifier
    ) external override isNotRegistered(address(verifier)) {
        s_modelCounter++;
        models[address(verifier)] = Model({
            id: s_modelCounter,
            verifier: verifier,
            owner: msg.sender
        });
        emit ModelRegistered(s_modelCounter, verifier, msg.sender);
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
        uint256 modelId = models[address(verifier)].id;
        inferences[nullifier] = Inference({
            modelId: modelId,
            instances: instances,
            prover: msg.sender,
            checked: false
        });

        emit InferenceVerified(modelId, proof, instances, msg.sender);
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
        isProver(inferences[nullifier], msg.sender)
        isNotChecked(inferences[nullifier])
    {
        inferences[nullifier].checked = true;
        Inference memory inference = inferences[nullifier];
        // run metrics
        uint256[] memory metrics = runMetrics(inference.instances);

        emit MetricsRun(inference.modelId, metrics);
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
    ) external view override returns (uint256 id, address owner) {
        return (models[verifier].id, models[verifier].owner);
    }
}
