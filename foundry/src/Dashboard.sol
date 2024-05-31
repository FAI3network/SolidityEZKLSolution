// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {IVerifier} from "./IVerifier.sol";
import {IDashboard} from "./IDashboard.sol";

contract Dashboard is IDashboard {
    struct Model {
        uint256 id;
        IVerifier verifier;
        address owner;
        // uint256[] history;
    }
    struct Inference {
        IVerifier verifier;
        uint256[] instances;
        address prover;
        bool checked;
    }

    mapping(address => Model) public models;
    mapping(bytes32 => bool) public nullifiers;
    mapping(bytes32 => Inference) public inferences;

    uint256 public s_modelCounter;

    constructor() {
        s_modelCounter = 0;
    }

    /**
     * @dev See {IDashboard-registerModel}
     */
    function registerModel(IVerifier verifier) external override {
        if (models[address(verifier)].id != 0) {
            revert("Model already registered");
        }
        s_modelCounter++;
        models[address(verifier)] = Model({
            id: s_modelCounter,
            verifier: verifier,
            owner: msg.sender
            // history: new uint256[](0)
        });
        emit ModelRegistered(s_modelCounter, verifier, msg.sender);
    }

    /**
     * @dev See {IDashboard-verifyInference}
     */
    function verifyInference(
        IVerifier verifier,
        bytes memory proof,
        uint256[] memory instances
    ) external override returns (bytes32) {
        bytes32 nullifier = keccak256(
            abi.encodePacked(address(verifier), proof, instances)
        );
        if (nullifiers[nullifier]) {
            revert("Inference already run");
        }
        nullifiers[nullifier] = true;
        if (!verifier.verifyProof(proof, instances)) {
            revert("Invalid proof");
        }

        inferences[nullifier] = Inference({
            verifier: verifier,
            instances: instances,
            prover: msg.sender,
            checked: false
        });

        emit InferenceVerified(verifier, proof, instances);
        return nullifier;
    }

    /**
     * @dev See {IDashboard-runFairness}
     */
    function runFairness(bytes32 nullifier) external override {
        if (
            (inferences[nullifier].prover != msg.sender) ||
            (inferences[nullifier].checked)
        ) {
            revert("Inference not found");
        }
        inferences[nullifier].checked = true;
        // run metrics
        // metrics = runMetrics(inferences[nullifier].instances);
        // update model history with metrics
        // models[address(inferences[nullifier].verifier)].history.push(metrics);
        // emit MetricsRun(address(inferences[nullifier].verifier));
    }

    /**
     * @dev See {IDashboard-getModel}
     */
    function getModel(
        address verifier
    ) external view override returns (uint256 id, address owner) {
        return (models[verifier].id, models[verifier].owner);
    }
}
