// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Leaderboard} from "../src/Leaderboard.sol";
import {Halo2Verifier as VerifierCreditBias} from "../src/credit-bias/VerifierCreditBias.sol";
import {Halo2Verifier as VerifierCreditUnbias} from "../src/credit-unbias/VerifierCreditUnbias.sol";

contract Deploy is Script {
    address deployer;
    address deployer2;
    HelperConfig internal helperConfig;
    Leaderboard public leaderboard;
    VerifierCreditBias public vfCBias;
    VerifierCreditUnbias public vfCUnbias;

    function setUp() public {}

    function run()
        public
        returns (Leaderboard, VerifierCreditBias, VerifierCreditUnbias)
    {
        helperConfig = new HelperConfig();
        (uint256 deployerKey, uint256 deployerKey2) = helperConfig
            .activeNetworkConfig();
        /* deploy leaderboard */
        vm.startBroadcast(deployerKey);

        deployer = vm.addr(deployerKey);
        console.log("Deployer: ", deployer);

        leaderboard = new Leaderboard();

        vm.stopBroadcast();

        /* deploy verifiers */
        vm.startBroadcast(deployerKey2);

        deployer2 = vm.addr(deployerKey2);
        console.log("Deployer2: ", deployer2);

        vfCBias = new VerifierCreditBias();
        vfCUnbias = new VerifierCreditUnbias();

        vm.stopBroadcast();

        return (leaderboard, vfCBias, vfCUnbias);
    }
}
