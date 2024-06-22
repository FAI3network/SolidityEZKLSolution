// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Metrics {
    struct Counter {
        uint256 count;
        uint256 positiveCount;
        uint256 tP;
        uint256 fP;
        uint256 tN;
        uint256 fN;
    }

    function statisticalParityDifference(
        uint privilegedCount,
        uint unprivilegedCount,
        uint privilegedPositiveCount,
        uint unprivilegedPositiveCount
    ) internal pure returns (int) {
        int privilegedProbability = int(
            (privilegedPositiveCount * 1e18) / privilegedCount
        );
        int unprivilegedProbability = int(
            (unprivilegedPositiveCount * 1e18) / unprivilegedCount
        );

        return unprivilegedProbability - privilegedProbability;
    }

    function disparateImpact(
        uint privilegedCount,
        uint unprivilegedCount,
        uint privilegedPositiveCount,
        uint unprivilegedPositiveCount
    ) internal pure returns (int) {
        int privilegedProbability = int(
            (privilegedPositiveCount * 1e18) / privilegedCount
        );
        int unprivilegedProbability = int(
            (unprivilegedPositiveCount * 1e18) / unprivilegedCount
        );

        // Ensure no division by zero
        require(
            privilegedProbability > 0,
            "Privileged group has no positive outcomes"
        );

        return (unprivilegedProbability * 1e18) / privilegedProbability;
    }

    function averageOddsDifference(
        uint privilegedTP,
        uint privilegedFP,
        uint privilegedTN,
        uint privilegedFN,
        uint unprivilegedTP,
        uint unprivilegedFP,
        uint unprivilegedTN,
        uint unprivilegedFN
    ) internal pure returns (int) {
        int privilegedTPR = int(
            (privilegedTP * 1e18) / (privilegedTP + privilegedFN)
        );
        int unprivilegedTPR = int(
            (unprivilegedTP * 1e18) / (unprivilegedTP + unprivilegedFN)
        );
        int privilegedFPR = int(
            (privilegedFP * 1e18) / (privilegedFP + privilegedTN)
        );
        int unprivilegedFPR = int(
            (unprivilegedFP * 1e18) / (unprivilegedFP + unprivilegedTN)
        );

        return
            ((unprivilegedFPR - privilegedFPR) +
                (unprivilegedTPR - privilegedTPR)) / 2;
    }

    function equalOpportunityDifference(
        uint privilegedTP,
        uint privilegedFN,
        uint unprivilegedTP,
        uint unprivilegedFN
    ) internal pure returns (int) {
        int privilegedTPR = int(
            (privilegedTP * 1e18) / (privilegedTP + privilegedFN)
        );
        int unprivilegedTPR = int(
            (unprivilegedTP * 1e18) / (unprivilegedTP + unprivilegedFN)
        );

        return unprivilegedTPR - privilegedTPR;
    }

    function initializeCounter(
        bool[3][] memory relVariables
    )
        public
        pure
        returns (Counter memory privileged, Counter memory unprivileged)
    {
        for (uint256 i = 0; i < relVariables.length; i++) {
            bool[3] memory relVariable = relVariables[i];
            bool rel_target = relVariable[0];
            bool rel_privileged = relVariable[1];
            bool rel_predicted = relVariable[2];
            if (rel_privileged) {
                privileged.count++;
                if (rel_predicted) {
                    privileged.positiveCount++;
                    if (rel_target) {
                        privileged.tP++;
                    } else {
                        privileged.fP++;
                    }
                } else {
                    if (rel_target) {
                        privileged.fN++;
                    } else {
                        privileged.tN++;
                    }
                }
            } else {
                unprivileged.count++;
                if (rel_predicted) {
                    unprivileged.positiveCount++;
                    if (rel_target) {
                        unprivileged.tP++;
                    } else {
                        unprivileged.fP++;
                    }
                } else {
                    if (rel_target) {
                        unprivileged.fN++;
                    } else {
                        unprivileged.tN++;
                    }
                }
            }
        }
    }

    function runMetrics(
        bool[3][] memory relVariables
    ) public pure returns (int[] memory metrics) {
        require(relVariables.length > 0, "No data provided");
        (
            Counter memory privileged,
            Counter memory unprivileged
        ) = initializeCounter(relVariables);
        require(
            privileged.count > 0 && unprivileged.count > 0,
            "No data for one of the groups"
        );
        require(
            (privileged.tP + privileged.fN) > 0 &&
                (unprivileged.tP + unprivileged.fN) > 0,
            "No positive cases for one of the groups"
        );
        require(
            (privileged.fP + privileged.tN) > 0 &&
                (unprivileged.fP + unprivileged.tN) > 0,
            "No negative cases for one of the groups"
        );
        metrics = new int[](4);
        metrics[0] = statisticalParityDifference(
            privileged.count,
            unprivileged.count,
            privileged.positiveCount,
            unprivileged.positiveCount
        );
        metrics[1] = disparateImpact(
            privileged.count,
            unprivileged.count,
            privileged.positiveCount,
            unprivileged.positiveCount
        );
        metrics[2] = averageOddsDifference(
            privileged.tP,
            privileged.fP,
            privileged.tN,
            privileged.fN,
            unprivileged.tP,
            unprivileged.fP,
            unprivileged.tN,
            unprivileged.fN
        );
        metrics[3] = equalOpportunityDifference(
            privileged.tP,
            privileged.fN,
            unprivileged.tP,
            unprivileged.fN
        );
        return metrics;
    }
}
