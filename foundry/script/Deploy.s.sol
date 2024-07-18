// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Script, console} from "forge-std/Script.sol";
// import {HelperConfig} from "./HelperConfig.s.sol";
// import {Leaderboard} from "../src/Leaderboard.sol";
// import {Halo2Verifier as VerifierCreditBias} from "../src/credit-bias/VerifierCreditBias.sol";
// import {Halo2Verifier as VerifierCreditUnbias} from "../src/credit-unbias/VerifierCreditUnbias.sol";
// import {Metrics} from "../src/metrics-lib/Metrics.sol";

// contract DeployLeaderboard is Script {
//     HelperConfig internal helperConfig;
//     Leaderboard public leaderboard;
//     address public metrics;

//     function setUp() public {}

//     function run() public returns (Leaderboard) {
//         helperConfig = new HelperConfig();
//         (uint256 deployerKey, ) = helperConfig.activeNetworkConfig();
//         /* deploy leaderboard */
//         vm.startBroadcast(deployerKey);
//         console.log("Deployer: ", vm.addr(deployerKey));
//         metrics = address(Metrics);
//         leaderboard = new Leaderboard(metrics);
//         vm.stopBroadcast();
//         return (leaderboard);
//     }
// }

// contract DeployVFCBias is Script {
//     HelperConfig internal helperConfig;
//     VerifierCreditBias vfCBias;

//     function run() public returns (VerifierCreditBias) {
//         helperConfig = new HelperConfig();
//         (, uint256 deployerKey2) = helperConfig.activeNetworkConfig();

//         /* deploy verifier credit bias */
//         vm.startBroadcast(deployerKey2);

//         console.log("Deployer2: ", vm.addr(deployerKey2));

//         vfCBias = new VerifierCreditBias();

//         vm.stopBroadcast();

//         return (vfCBias);
//     }
// }

// contract DeployVFCUnbias is Script {
//     HelperConfig internal helperConfig;
//     VerifierCreditUnbias vfCUnbias;

//     function run() public returns (VerifierCreditUnbias) {
//         helperConfig = new HelperConfig();
//         (, uint256 deployerKey2) = helperConfig.activeNetworkConfig();

//         /* deploy verifier credit unbias */
//         vm.startBroadcast(deployerKey2);

//         console.log("Deployer2: ", vm.addr(deployerKey2));

//         vfCUnbias = new VerifierCreditUnbias();

//         vm.stopBroadcast();

//         return (vfCUnbias);
//     }
// }
