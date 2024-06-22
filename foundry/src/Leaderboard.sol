// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVerifier} from "./IVerifier.sol";
import {ILeaderboard} from "./ILeaderboard.sol";
import {IMetrics} from "./metrics-lib/IMetrics.sol";

contract Leaderboard is ILeaderboard {
    struct Model {
        address owner;
        string modelURI;
    }
    struct Inference {
        IVerifier verifier;
        bool[3][] relVariables; // relevant variables [[target, priviliged, predicted], ...]
        address prover;
        bool checked; // check if the inference has been used to get metrics
    }

    // verifier => model
    mapping(address => Model) public s_models;
    // nullifier => inference
    mapping(bytes32 => Inference) public s_inferences;

    address public immutable i_metricsLib;

    constructor(address _metricsLib) {
        i_metricsLib = _metricsLib;
    }

    /* Modifiers */
    modifier isNotRegistered(address verifier) {
        Model memory model = s_models[verifier];
        if (model.owner != address(0)) {
            revert ModelAlreadyRegistered();
        }
        _;
    }

    modifier isRegistered(address verifier) {
        Model memory model = s_models[verifier];
        if (model.owner == address(0)) {
            revert ModelNotRegistered();
        }
        _;
    }

    modifier isOwner(address verifier) {
        Model memory model = s_models[verifier];
        if (model.owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    modifier isNotVerified(bytes32 nullifier) {
        Inference memory inference = s_inferences[nullifier];
        if (inference.prover != address(0)) {
            revert InferenceAlreadyVerified();
        }
        _;
    }

    modifier inferenceExists(bytes32 nullifier) {
        Inference memory inference = s_inferences[nullifier];
        if (inference.prover == address(0)) {
            revert InferenceNotExists();
        }
        _;
    }

    modifier isProver(bytes32 nullifier, address prover) {
        Inference memory inference = s_inferences[nullifier];
        if (inference.prover != prover) {
            revert NotProver();
        }
        _;
    }

    modifier isNotChecked(bytes32 nullifier) {
        Inference memory inference = s_inferences[nullifier];
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
        s_models[address(verifier)] = Model({
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
        delete s_models[address(verifier)];
        emit ModelDeleted(verifier, msg.sender);
    }

    /**
     * @dev See {ILeaderboard-verifyInference}
     */
    function verifyInference(
        IVerifier verifier,
        bytes memory proof,
        uint256[] memory instances,
        bool[3][] memory relVariables
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
        s_inferences[nullifier] = Inference({
            verifier: verifier,
            relVariables: relVariables,
            prover: msg.sender,
            checked: false
        });

        emit InferenceVerified(
            verifier,
            proof,
            instances,
            relVariables,
            msg.sender
        );
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
        returns (int256[] memory metrics)
    {
        s_inferences[nullifier].checked = true;
        Inference memory inference = s_inferences[nullifier];
        // run metrics
        IMetrics metricsLib = IMetrics(i_metricsLib);
        metrics = metricsLib.runMetrics(inference.relVariables);

        emit MetricsRun(inference.verifier, metrics, nullifier);
        return metrics;
    }

    /**
     * @dev See {ILeaderboard-getModel}
     */
    function getModel(
        address verifier
    ) external view override returns (address owner, string memory modelURI) {
        Model memory model = s_models[verifier];
        return (model.owner, model.modelURI);
    }

    /**
     * @dev See {ILeaderboard-getModelURI}
     */
    function getModelURI(
        address verifier
    ) external view returns (string memory modelURI) {
        Model memory model = s_models[verifier];
        return (model.modelURI);
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
        returns (
            IVerifier verifier,
            bool[3][] memory relVariables,
            address prover
        )
    {
        Inference memory inference = s_inferences[nullifier];
        return (inference.verifier, inference.relVariables, inference.prover);
    }
}
