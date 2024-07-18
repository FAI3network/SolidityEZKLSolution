// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVerifier} from "./IVerifier.sol";
import {ILeaderboard} from "./ILeaderboard.sol";
import {IMetrics} from "./metrics-lib/IMetrics2.sol";

contract Leaderboard2 is ILeaderboard {
    struct ConvMatrix {
        uint256 tP;
        uint256 fP;
        uint256 tN;
        uint256 fN;
    }

    struct Model {
        address owner;
        string modelURI;
        uint256 priviligedIndex;
        uint256 predictedIndex;
        bool[3][] history; // history of inferences [[target, priviliged, predicted], ...]
    }

    // verifier => model
    mapping(address => Model) public s_models;
    // nullifier => boolean (true if the inference has already been verified)
    mapping(bytes32 => bool) public s_inferences;

    // metrics library
    address public immutable i_metricsLib;

    constructor(address _metricsLib) {
        i_metricsLib = _metricsLib;
    }

    /* Modifiers */
    modifier isNotRegistered(address verifier) {
        if (s_models[verifier].owner != address(0)) {
            revert ModelAlreadyRegistered();
        }
        _;
    }

    modifier isRegistered(address verifier) {
        if (s_models[verifier].owner == address(0)) {
            revert ModelNotRegistered();
        }
        _;
    }

    modifier isOwner(address verifier) {
        if (s_models[verifier].owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    modifier isNotVerified(bytes32 nullifier) {
        if (s_inferences[nullifier]) {
            revert InferenceAlreadyVerified();
        }
        _;
    }

    modifier isLengthValid(uint256 length, address verifier) {
        Model memory model = s_models[verifier];
        if (length < model.priviligedIndex || length < model.predictedIndex) {
            revert InvalidLength();
        }
        _;
    }

    /**
     * @dev See {ILeaderboard-registerModel}
     */
    function registerModel(
        IVerifier verifier,
        string memory modelURI,
        uint256 priviligedIndex,
        uint256 predictedIndex
    ) external override isNotRegistered(address(verifier)) {
        if (bytes(modelURI).length == 0) {
            revert URINotProvided();
        }
        s_models[address(verifier)] = Model({
            owner: msg.sender,
            modelURI: modelURI,
            priviligedIndex: priviligedIndex,
            predictedIndex: predictedIndex,
            history: new bool[3][](0)
        });
        emit ModelRegistered(verifier, msg.sender, modelURI);
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
        uint256 target,
        uint256 privId
    )
        external
        override
        isRegistered(address(verifier))
        isNotVerified(
            keccak256(abi.encodePacked(address(verifier), proof, instances))
        )
        isLengthValid(instances.length, address(verifier))
        returns (bytes32)
    {
        bytes32 nullifier = keccak256(
            abi.encodePacked(address(verifier), proof, instances)
        );
        // verify proof
        if (!verifier.verifyProof(proof, instances)) {
            revert InvalidProof();
        }
        s_inferences[nullifier] = true;

        uint256 predIndex = s_models[address(verifier)].predictedIndex;
        uint256 privIndex = s_models[address(verifier)].priviligedIndex;
        s_models[address(verifier)].history.push(
            [
                target == 1,
                instances[privIndex] == privId,
                instances[predIndex] == 1
            ]
        );

        emit InferenceVerified(verifier, proof, instances, msg.sender);
        return nullifier;
    }

    /**
     * @dev See {ILeaderboard-runFairness}
     */
    function runFairness(
        IVerifier verifier
    )
        external
        override
        isRegistered(address(verifier))
        returns (int256[] memory metrics)
    {
        Model memory model = s_models[address(verifier)];

        // run metrics
        metrics = IMetrics(i_metricsLib).runMetrics(model.history);

        emit MetricsRun(address(verifier), metrics);
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
}
