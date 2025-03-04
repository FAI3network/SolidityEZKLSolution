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
        uint256 pTP,
        uint256 pFP,
        uint256 pTN,
        uint256 pFN,
        uint256 uTP,
        uint256 uFP,
        uint256 uTN,
        uint256 uFN
    ) public pure returns (int[] memory metrics) {
        require(
            (pTP + pFP + pTN + pFN) > 0 && (uTP + uFP + uTN + uFN) > 0,
            "No data for one of the groups"
        );
        require(
            (pTP + pFN) > 0 && (uTP + uFN) > 0,
            "No positive cases for one of the groups"
        );
        require(
            (pFP + pTN) > 0 && (uFP + uTN) > 0,
            "No negative cases for one of the groups"
        );
        metrics = new int[](4);
        metrics[0] = statisticalParityDifference(
            (pTP + pFP + pTN + pFN),
            (uTP + uFP + uTN + uFN),
            (pTP + pFP),
            (uTP + uFP)
        );
        metrics[1] = disparateImpact(
            (pTP + pFP + pTN + pFN),
            (uTP + uFP + uTN + uFN),
            (pTP + pFP),
            (uTP + uFP)
        );
        metrics[2] = averageOddsDifference(
            pTP,
            pFP,
            pTN,
            pFN,
            uTP,
            uFP,
            uTN,
            uFN
        );
        metrics[3] = equalOpportunityDifference(pTP, pFN, uTP, uFN);
        return metrics;
    }
}
