// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetrics {
    function runMetrics(
        uint256 pTP,
        uint256 pFP,
        uint256 pTN,
        uint256 pFN,
        uint256 uTP,
        uint256 uFP,
        uint256 uTN,
        uint256 uFN
    ) external pure returns (int[] memory metrics);
}
