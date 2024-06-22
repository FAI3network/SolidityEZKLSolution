// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetrics {
    function runMetrics(
        bool[3][] calldata relVariables
    ) external pure returns (int[] memory metrics);
}
