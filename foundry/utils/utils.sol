// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";

contract Utils is Test {
    function setParams(
        string memory i_proof,
        string[] memory inst
    ) public returns (bytes memory proof, uint256[] memory instances) {
        string[] memory input_proof = new string[](3);
        input_proof[0] = "echo";
        input_proof[1] = "-n";
        input_proof[2] = i_proof;
        proof = vm.ffi(input_proof);

        instances = new uint256[](inst.length);
        // inspiration: https://github.com/zkonduit/cryptoidol-contracts/blob/16d1741aa55aba5287ba46b136409d67d0b3da04/test/CryptoIdol.t.sol#L103
        for (uint256 i = 0; i < inst.length; i++) {
            string[] memory input_instance_i = new string[](3);
            input_instance_i[0] = "echo";
            input_instance_i[1] = "-n";
            input_instance_i[2] = inst[i];

            bytes memory res_instance_i = vm.ffi(input_instance_i);
            // console.logBytes(res_instance_i);
            uint256 instance_i = abi.decode(res_instance_i, (uint256));
            instances[i] = instance_i; // instance i in uint256
            // console.logUint(instances[i]);
        }
        return (proof, instances);
    }
}
