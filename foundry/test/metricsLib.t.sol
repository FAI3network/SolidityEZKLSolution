// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Metrics} from "../src/metrics-lib/Metrics.sol";

contract vfContractTest is Test {
    bool[3][] I_VARS;

    function setUp() public {
        I_VARS = [
            [true, true, true], // TP for privileged
            [false, true, false], // TN for privileged
            [true, false, true], // TP for unprivileged
            [false, false, false], // TN for unprivileged
            [true, true, true], // TP for privileged
            [false, true, false], // TN for privileged
            [true, false, true], // TP for unprivileged
            [true, false, true], // TP for unprivileged
            [false, true, true], // FP for privileged
            [false, true, true], // FP for privileged
            [true, false, false], // FN for unprivileged
            [false, false, false], // TN for unprivileged
            [true, true, true], // TP for privileged
            [false, true, false], // TN for privileged
            [false, true, true], // FP for privileged
            [true, false, true], // TP for unprivileged
            [true, false, true], // TP for unprivileged
            [false, false, false] // TN for unprivileged
        ];
    }

    function testInitializeCounter(
        bool[3][] memory relV
    ) public view returns (Metrics.Counter memory, Metrics.Counter memory) {
        (Metrics.Counter memory p, Metrics.Counter memory up) = Metrics
            .initializeCounter(relV);
        console.log("privileged : ");
        console.log("count: ", p.count, " positiveCount: ", p.positiveCount);
        console.log("TP: ", p.tP, " FP: ", p.fP);
        console.log("TN: ", p.tN, " FN: ", p.fN);

        console.log("unprivileged : ");
        console.log("count: ", up.count, " positiveCount: ", up.positiveCount);
        console.log("TP: ", up.tP, " FP: ", up.fP);
        console.log("TN: ", up.tN, " FN: ", up.fN);

        return (p, up);
    }

    function testFuzz_runMetrics(bool[3][] memory relV) public {
        if (relV.length == 0) {
            vm.expectRevert("No data provided");
        } else {
            (Metrics.Counter memory p, Metrics.Counter memory up) = Metrics
                .initializeCounter(relV);
            if (p.count == 0 || up.count == 0) {
                vm.expectRevert("No data for one of the groups");
            } else if (p.tP + p.fN == 0 || up.tP + up.fN == 0) {
                vm.expectRevert("No positive cases for one of the groups");
            } else if (p.fP + p.tN == 0 || up.fP + up.tN == 0) {
                vm.expectRevert("No negative cases for one of the groups");
            } else {
                int privilegedProbability = int(
                    (p.positiveCount * 1e18) / p.count
                );
                if (privilegedProbability == 0) {
                    vm.expectRevert(
                        "Privileged group has no positive outcomes"
                    );
                }
            }
        }
        int256[] memory metrics = Metrics.runMetrics(relV);
        console.log("metrics: ");
        for (uint256 i = 0; i < metrics.length; i++) {
            console.logInt(metrics[i]);
        }
    }

    function test_runMetrics() public {
        int256[] memory metrics = Metrics.runMetrics(I_VARS);
        console.log("metrics: ");
        for (uint256 i = 0; i < metrics.length; i++) {
            console.logInt(metrics[i]);
        }
    }
}
