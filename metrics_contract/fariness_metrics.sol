// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FairnessMetrics {

    struct DataPoint {
        bool target;  // Target variable binary
        bool privileged;  // Bool column indicating if the observation is privileged or not
        bool predicted;  // Predicted value from the classifier
    }

    DataPoint[] public dataPoints;

    function addDataPoint(bool _target, bool _privileged, bool _predicted) public {
        dataPoints.push(DataPoint(_target, _privileged, _predicted));
    }

    function statisticalParityDifference() public view returns (int) {
        uint privilegedCount = 0;
        uint unprivilegedCount = 0;
        uint privilegedPositiveCount = 0;
        uint unprivilegedPositiveCount = 0;

        for (uint i = 0; i < dataPoints.length; i++) {
            if (dataPoints[i].privileged) {
                privilegedCount++;
                if (dataPoints[i].predicted) {
                    privilegedPositiveCount++;
                }
            } else {
                unprivilegedCount++;
                if (dataPoints[i].predicted) {
                    unprivilegedPositiveCount++;
                }
            }
        }

        require(privilegedCount > 0 && unprivilegedCount > 0, "No data for one of the groups");

        int privilegedProbability = int(privilegedPositiveCount * 1e18 / privilegedCount);
        int unprivilegedProbability = int(unprivilegedPositiveCount * 1e18 / unprivilegedCount);

        return unprivilegedProbability - privilegedProbability;
    }

    function disparateImpact() public view returns (int) {
        uint privilegedCount = 0;
        uint unprivilegedCount = 0;
        uint privilegedPositiveCount = 0;
        uint unprivilegedPositiveCount = 0;

        for (uint i = 0; i < dataPoints.length; i++) {
            if (dataPoints[i].privileged) {
                privilegedCount++;
                if (dataPoints[i].predicted) {
                    privilegedPositiveCount++;
                }
            } else {
                unprivilegedCount++;
                if (dataPoints[i].predicted) {
                    unprivilegedPositiveCount++;
                }
            }
        }

        require(privilegedCount > 0 && unprivilegedCount > 0, "No data for one of the groups");

        int privilegedProbability = int(privilegedPositiveCount * 1e18 / privilegedCount);
        int unprivilegedProbability = int(unprivilegedPositiveCount * 1e18 / unprivilegedCount);

        // Ensure no division by zero
        require(privilegedProbability > 0, "Privileged group has no positive outcomes");

        return (unprivilegedProbability * 1e18) / privilegedProbability;
    }

    function averageOddsDifference() public view returns (int) {
        uint privilegedTP = 0;
        uint privilegedFP = 0;
        uint privilegedTN = 0;
        uint privilegedFN = 0;
        uint unprivilegedTP = 0;
        uint unprivilegedFP = 0;
        uint unprivilegedTN = 0;
        uint unprivilegedFN = 0;

        for (uint i = 0; i < dataPoints.length; i++) {
            if (dataPoints[i].privileged) {
                if (dataPoints[i].predicted && dataPoints[i].target) {
                    privilegedTP++;
                } else if (dataPoints[i].predicted && !dataPoints[i].target) {
                    privilegedFP++;
                } else if (!dataPoints[i].predicted && dataPoints[i].target) {
                    privilegedFN++;
                } else {
                    privilegedTN++;
                }
            } else {
                if (dataPoints[i].predicted && dataPoints[i].target) {
                    unprivilegedTP++;
                } else if (dataPoints[i].predicted && !dataPoints[i].target) {
                    unprivilegedFP++;
                } else if (!dataPoints[i].predicted && dataPoints[i].target) {
                    unprivilegedFN++;
                } else {
                    unprivilegedTN++;
                }
            }
        }

        require((privilegedTP + privilegedFN) > 0 && (unprivilegedTP + unprivilegedFN) > 0, "No positive cases for one of the groups");
        require((privilegedFP + privilegedTN) > 0 && (unprivilegedFP + unprivilegedTN) > 0, "No negative cases for one of the groups");

        int privilegedTPR = int(privilegedTP * 1e18 / (privilegedTP + privilegedFN));
        int unprivilegedTPR = int(unprivilegedTP * 1e18 / (unprivilegedTP + unprivilegedFN));
        int privilegedFPR = int(privilegedFP * 1e18 / (privilegedFP + privilegedTN));
        int unprivilegedFPR = int(unprivilegedFP * 1e18 / (unprivilegedFP + unprivilegedTN));

        return ((unprivilegedFPR - privilegedFPR) + (unprivilegedTPR - privilegedTPR)) / 2;
    }

    function equalOpportunityDifference() public view returns (int) {
        uint privilegedTP = 0;
        uint privilegedFN = 0;
        uint unprivilegedTP = 0;
        uint unprivilegedFN = 0;

        for (uint i = 0; i < dataPoints.length; i++) {
            if (dataPoints[i].privileged) {
                if (dataPoints[i].predicted && dataPoints[i].target) {
                    privilegedTP++;
                } else if (!dataPoints[i].predicted && dataPoints[i].target) {
                    privilegedFN++;
                }
            } else {
                if (dataPoints[i].predicted && dataPoints[i].target) {
                    unprivilegedTP++;
                } else if (!dataPoints[i].predicted && dataPoints[i].target) {
                    unprivilegedFN++;
                }
            }
        }

        require((privilegedTP + privilegedFN) > 0 && (unprivilegedTP + unprivilegedFN) > 0, "No positive cases for one of the groups");

        int privilegedTPR = int(privilegedTP * 1e18 / (privilegedTP + privilegedFN));
        int unprivilegedTPR = int(unprivilegedTP * 1e18 / (unprivilegedTP + unprivilegedFN));

        return unprivilegedTPR - privilegedTPR;
    }

    // Function to add example data points
    function addExampleDataPoints() public {
        addDataPoint(true, true, true);   // TP for privileged
        addDataPoint(false, true, false); // TN for privileged
        addDataPoint(true, false, true);  // TP for unprivileged
        addDataPoint(false, false, false);// TN for unprivileged
        addDataPoint(true, true, true);   // TP for privileged
        addDataPoint(false, true, false); // TN for privileged
        addDataPoint(true, false, true);  // TP for unprivileged
        addDataPoint(true, false, true);  // TP for unprivileged
    }
}

