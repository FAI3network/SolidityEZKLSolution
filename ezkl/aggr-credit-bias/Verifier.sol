// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Halo2Verifier {
    uint256 internal constant    PROOF_LEN_CPTR = 0x6014f51944;
    uint256 internal constant        PROOF_CPTR = 0x64;
    uint256 internal constant NUM_INSTANCE_CPTR = 0x0c44;
    uint256 internal constant     INSTANCE_CPTR = 0x0c64;

    uint256 internal constant FIRST_QUOTIENT_X_CPTR = 0x04e4;
    uint256 internal constant  LAST_QUOTIENT_X_CPTR = 0x05a4;

    uint256 internal constant                VK_MPTR = 0x0480;
    uint256 internal constant         VK_DIGEST_MPTR = 0x0480;
    uint256 internal constant     NUM_INSTANCES_MPTR = 0x04a0;
    uint256 internal constant                 K_MPTR = 0x04c0;
    uint256 internal constant             N_INV_MPTR = 0x04e0;
    uint256 internal constant             OMEGA_MPTR = 0x0500;
    uint256 internal constant         OMEGA_INV_MPTR = 0x0520;
    uint256 internal constant    OMEGA_INV_TO_L_MPTR = 0x0540;
    uint256 internal constant   HAS_ACCUMULATOR_MPTR = 0x0560;
    uint256 internal constant        ACC_OFFSET_MPTR = 0x0580;
    uint256 internal constant     NUM_ACC_LIMBS_MPTR = 0x05a0;
    uint256 internal constant NUM_ACC_LIMB_BITS_MPTR = 0x05c0;
    uint256 internal constant              G1_X_MPTR = 0x05e0;
    uint256 internal constant              G1_Y_MPTR = 0x0600;
    uint256 internal constant            G2_X_1_MPTR = 0x0620;
    uint256 internal constant            G2_X_2_MPTR = 0x0640;
    uint256 internal constant            G2_Y_1_MPTR = 0x0660;
    uint256 internal constant            G2_Y_2_MPTR = 0x0680;
    uint256 internal constant      NEG_S_G2_X_1_MPTR = 0x06a0;
    uint256 internal constant      NEG_S_G2_X_2_MPTR = 0x06c0;
    uint256 internal constant      NEG_S_G2_Y_1_MPTR = 0x06e0;
    uint256 internal constant      NEG_S_G2_Y_2_MPTR = 0x0700;

    uint256 internal constant CHALLENGE_MPTR = 0x0c20;

    uint256 internal constant THETA_MPTR = 0x0c20;
    uint256 internal constant  BETA_MPTR = 0x0c40;
    uint256 internal constant GAMMA_MPTR = 0x0c60;
    uint256 internal constant     Y_MPTR = 0x0c80;
    uint256 internal constant     X_MPTR = 0x0ca0;
    uint256 internal constant  ZETA_MPTR = 0x0cc0;
    uint256 internal constant    NU_MPTR = 0x0ce0;
    uint256 internal constant    MU_MPTR = 0x0d00;

    uint256 internal constant       ACC_LHS_X_MPTR = 0x0d20;
    uint256 internal constant       ACC_LHS_Y_MPTR = 0x0d40;
    uint256 internal constant       ACC_RHS_X_MPTR = 0x0d60;
    uint256 internal constant       ACC_RHS_Y_MPTR = 0x0d80;
    uint256 internal constant             X_N_MPTR = 0x0da0;
    uint256 internal constant X_N_MINUS_1_INV_MPTR = 0x0dc0;
    uint256 internal constant          L_LAST_MPTR = 0x0de0;
    uint256 internal constant         L_BLIND_MPTR = 0x0e00;
    uint256 internal constant             L_0_MPTR = 0x0e20;
    uint256 internal constant   INSTANCE_EVAL_MPTR = 0x0e40;
    uint256 internal constant   QUOTIENT_EVAL_MPTR = 0x0e60;
    uint256 internal constant      QUOTIENT_X_MPTR = 0x0e80;
    uint256 internal constant      QUOTIENT_Y_MPTR = 0x0ea0;
    uint256 internal constant          R_EVAL_MPTR = 0x0ec0;
    uint256 internal constant   PAIRING_LHS_X_MPTR = 0x0ee0;
    uint256 internal constant   PAIRING_LHS_Y_MPTR = 0x0f00;
    uint256 internal constant   PAIRING_RHS_X_MPTR = 0x0f20;
    uint256 internal constant   PAIRING_RHS_Y_MPTR = 0x0f40;

    function verifyProof(
        bytes calldata proof,
        uint256[] calldata instances
    ) public returns (bool) {
        assembly {
            // Read EC point (x, y) at (proof_cptr, proof_cptr + 0x20),
            // and check if the point is on affine plane,
            // and store them in (hash_mptr, hash_mptr + 0x20).
            // Return updated (success, proof_cptr, hash_mptr).
            function read_ec_point(success, proof_cptr, hash_mptr, q) -> ret0, ret1, ret2 {
                let x := calldataload(proof_cptr)
                let y := calldataload(add(proof_cptr, 0x20))
                ret0 := and(success, lt(x, q))
                ret0 := and(ret0, lt(y, q))
                ret0 := and(ret0, eq(mulmod(y, y, q), addmod(mulmod(x, mulmod(x, x, q), q), 3, q)))
                mstore(hash_mptr, x)
                mstore(add(hash_mptr, 0x20), y)
                ret1 := add(proof_cptr, 0x40)
                ret2 := add(hash_mptr, 0x40)
            }

            // Squeeze challenge by keccak256(memory[0..hash_mptr]),
            // and store hash mod r as challenge in challenge_mptr,
            // and push back hash in 0x00 as the first input for next squeeze.
            // Return updated (challenge_mptr, hash_mptr).
            function squeeze_challenge(challenge_mptr, hash_mptr, r) -> ret0, ret1 {
                let hash := keccak256(0x00, hash_mptr)
                mstore(challenge_mptr, mod(hash, r))
                mstore(0x00, hash)
                ret0 := add(challenge_mptr, 0x20)
                ret1 := 0x20
            }

            // Squeeze challenge without absorbing new input from calldata,
            // by putting an extra 0x01 in memory[0x20] and squeeze by keccak256(memory[0..21]),
            // and store hash mod r as challenge in challenge_mptr,
            // and push back hash in 0x00 as the first input for next squeeze.
            // Return updated (challenge_mptr).
            function squeeze_challenge_cont(challenge_mptr, r) -> ret {
                mstore8(0x20, 0x01)
                let hash := keccak256(0x00, 0x21)
                mstore(challenge_mptr, mod(hash, r))
                mstore(0x00, hash)
                ret := add(challenge_mptr, 0x20)
            }

            // Batch invert values in memory[mptr_start..mptr_end] in place.
            // Return updated (success).
            function batch_invert(success, mptr_start, mptr_end, r) -> ret {
                let gp_mptr := mptr_end
                let gp := mload(mptr_start)
                let mptr := add(mptr_start, 0x20)
                for
                    {}
                    lt(mptr, sub(mptr_end, 0x20))
                    {}
                {
                    gp := mulmod(gp, mload(mptr), r)
                    mstore(gp_mptr, gp)
                    mptr := add(mptr, 0x20)
                    gp_mptr := add(gp_mptr, 0x20)
                }
                gp := mulmod(gp, mload(mptr), r)

                mstore(gp_mptr, 0x20)
                mstore(add(gp_mptr, 0x20), 0x20)
                mstore(add(gp_mptr, 0x40), 0x20)
                mstore(add(gp_mptr, 0x60), gp)
                mstore(add(gp_mptr, 0x80), sub(r, 2))
                mstore(add(gp_mptr, 0xa0), r)
                ret := and(success, staticcall(gas(), 0x05, gp_mptr, 0xc0, gp_mptr, 0x20))
                let all_inv := mload(gp_mptr)

                let first_mptr := mptr_start
                let second_mptr := add(first_mptr, 0x20)
                gp_mptr := sub(gp_mptr, 0x20)
                for
                    {}
                    lt(second_mptr, mptr)
                    {}
                {
                    let inv := mulmod(all_inv, mload(gp_mptr), r)
                    all_inv := mulmod(all_inv, mload(mptr), r)
                    mstore(mptr, inv)
                    mptr := sub(mptr, 0x20)
                    gp_mptr := sub(gp_mptr, 0x20)
                }
                let inv_first := mulmod(all_inv, mload(second_mptr), r)
                let inv_second := mulmod(all_inv, mload(first_mptr), r)
                mstore(first_mptr, inv_first)
                mstore(second_mptr, inv_second)
            }

            // Add (x, y) into point at (0x00, 0x20).
            // Return updated (success).
            function ec_add_acc(success, x, y) -> ret {
                mstore(0x40, x)
                mstore(0x60, y)
                ret := and(success, staticcall(gas(), 0x06, 0x00, 0x80, 0x00, 0x40))
            }

            // Scale point at (0x00, 0x20) by scalar.
            function ec_mul_acc(success, scalar) -> ret {
                mstore(0x40, scalar)
                ret := and(success, staticcall(gas(), 0x07, 0x00, 0x60, 0x00, 0x40))
            }

            // Add (x, y) into point at (0x80, 0xa0).
            // Return updated (success).
            function ec_add_tmp(success, x, y) -> ret {
                mstore(0xc0, x)
                mstore(0xe0, y)
                ret := and(success, staticcall(gas(), 0x06, 0x80, 0x80, 0x80, 0x40))
            }

            // Scale point at (0x80, 0xa0) by scalar.
            // Return updated (success).
            function ec_mul_tmp(success, scalar) -> ret {
                mstore(0xc0, scalar)
                ret := and(success, staticcall(gas(), 0x07, 0x80, 0x60, 0x80, 0x40))
            }

            // Perform pairing check.
            // Return updated (success).
            function ec_pairing(success, lhs_x, lhs_y, rhs_x, rhs_y) -> ret {
                mstore(0x00, lhs_x)
                mstore(0x20, lhs_y)
                mstore(0x40, mload(G2_X_1_MPTR))
                mstore(0x60, mload(G2_X_2_MPTR))
                mstore(0x80, mload(G2_Y_1_MPTR))
                mstore(0xa0, mload(G2_Y_2_MPTR))
                mstore(0xc0, rhs_x)
                mstore(0xe0, rhs_y)
                mstore(0x100, mload(NEG_S_G2_X_1_MPTR))
                mstore(0x120, mload(NEG_S_G2_X_2_MPTR))
                mstore(0x140, mload(NEG_S_G2_Y_1_MPTR))
                mstore(0x160, mload(NEG_S_G2_Y_2_MPTR))
                ret := and(success, staticcall(gas(), 0x08, 0x00, 0x180, 0x00, 0x20))
                ret := and(ret, mload(0x00))
            }

            // Modulus
            let q := 21888242871839275222246405745257275088696311157297823662689037894645226208583 // BN254 base field
            let r := 21888242871839275222246405745257275088548364400416034343698204186575808495617 // BN254 scalar field

            // Initialize success as true
            let success := true

            {
                // Load vk_digest and num_instances of vk into memory
                mstore(0x0480, 0x14793268f2864395db8004eb2a557cb80f20be15f605fc35eabd99d187470908) // vk_digest
                mstore(0x04a0, 0x0000000000000000000000000000000000000000000000000000000000000013) // num_instances

                // Check valid length of proof
                success := and(success, eq(0x0be0, calldataload(sub(PROOF_LEN_CPTR, 0x6014F51900))))

                // Check valid length of instances
                let num_instances := mload(NUM_INSTANCES_MPTR)
                success := and(success, eq(num_instances, calldataload(NUM_INSTANCE_CPTR)))

                // Absorb vk diegst
                mstore(0x00, mload(VK_DIGEST_MPTR))

                // Read instances and witness commitments and generate challenges
                let hash_mptr := 0x20
                let instance_cptr := INSTANCE_CPTR
                for
                    { let instance_cptr_end := add(instance_cptr, mul(0x20, num_instances)) }
                    lt(instance_cptr, instance_cptr_end)
                    {}
                {
                    let instance := calldataload(instance_cptr)
                    success := and(success, lt(instance, r))
                    mstore(hash_mptr, instance)
                    instance_cptr := add(instance_cptr, 0x20)
                    hash_mptr := add(hash_mptr, 0x20)
                }

                let proof_cptr := PROOF_CPTR
                let challenge_mptr := CHALLENGE_MPTR

                // Phase 1
                for
                    { let proof_cptr_end := add(proof_cptr, 0x0140) }
                    lt(proof_cptr, proof_cptr_end)
                    {}
                {
                    success, proof_cptr, hash_mptr := read_ec_point(success, proof_cptr, hash_mptr, q)
                }

                challenge_mptr, hash_mptr := squeeze_challenge(challenge_mptr, hash_mptr, r)

                // Phase 2
                for
                    { let proof_cptr_end := add(proof_cptr, 0x0140) }
                    lt(proof_cptr, proof_cptr_end)
                    {}
                {
                    success, proof_cptr, hash_mptr := read_ec_point(success, proof_cptr, hash_mptr, q)
                }

                challenge_mptr, hash_mptr := squeeze_challenge(challenge_mptr, hash_mptr, r)
                challenge_mptr := squeeze_challenge_cont(challenge_mptr, r)

                // Phase 3
                for
                    { let proof_cptr_end := add(proof_cptr, 0x0200) }
                    lt(proof_cptr, proof_cptr_end)
                    {}
                {
                    success, proof_cptr, hash_mptr := read_ec_point(success, proof_cptr, hash_mptr, q)
                }

                challenge_mptr, hash_mptr := squeeze_challenge(challenge_mptr, hash_mptr, r)

                // Phase 4
                for
                    { let proof_cptr_end := add(proof_cptr, 0x0100) }
                    lt(proof_cptr, proof_cptr_end)
                    {}
                {
                    success, proof_cptr, hash_mptr := read_ec_point(success, proof_cptr, hash_mptr, q)
                }

                challenge_mptr, hash_mptr := squeeze_challenge(challenge_mptr, hash_mptr, r)

                // Read evaluations
                for
                    { let proof_cptr_end := add(proof_cptr, 0x05e0) }
                    lt(proof_cptr, proof_cptr_end)
                    {}
                {
                    let eval := calldataload(proof_cptr)
                    success := and(success, lt(eval, r))
                    mstore(hash_mptr, eval)
                    proof_cptr := add(proof_cptr, 0x20)
                    hash_mptr := add(hash_mptr, 0x20)
                }

                // Read batch opening proof and generate challenges
                challenge_mptr, hash_mptr := squeeze_challenge(challenge_mptr, hash_mptr, r)       // zeta
                challenge_mptr := squeeze_challenge_cont(challenge_mptr, r)                        // nu

                success, proof_cptr, hash_mptr := read_ec_point(success, proof_cptr, hash_mptr, q) // W

                challenge_mptr, hash_mptr := squeeze_challenge(challenge_mptr, hash_mptr, r)       // mu

                success, proof_cptr, hash_mptr := read_ec_point(success, proof_cptr, hash_mptr, q) // W'

                // Load full vk into memory
                mstore(0x0480, 0x14793268f2864395db8004eb2a557cb80f20be15f605fc35eabd99d187470908) // vk_digest
                mstore(0x04a0, 0x0000000000000000000000000000000000000000000000000000000000000013) // num_instances
                mstore(0x04c0, 0x0000000000000000000000000000000000000000000000000000000000000016) // k
                mstore(0x04e0, 0x30644db14ff7d4a4f1cf9ed5406a7e5722d273a7aa184eaa5e1fb0846829b041) // n_inv
                mstore(0x0500, 0x18c95f1ae6514e11a1b30fd7923947c5ffcec5347f16e91b4dd654168326bede) // omega
                mstore(0x0520, 0x134f571fe34eb8c7b1685e875b324820e199bd70157493377cd65b204d1a3964) // omega_inv
                mstore(0x0540, 0x182fa146dab5070e1897c235ff7425a25d09f820206545e69bf946c2f6057429) // omega_inv_to_l
                mstore(0x0560, 0x0000000000000000000000000000000000000000000000000000000000000001) // has_accumulator
                mstore(0x0580, 0x0000000000000000000000000000000000000000000000000000000000000000) // acc_offset
                mstore(0x05a0, 0x0000000000000000000000000000000000000000000000000000000000000004) // num_acc_limbs
                mstore(0x05c0, 0x0000000000000000000000000000000000000000000000000000000000000044) // num_acc_limb_bits
                mstore(0x05e0, 0x0000000000000000000000000000000000000000000000000000000000000001) // g1_x
                mstore(0x0600, 0x0000000000000000000000000000000000000000000000000000000000000002) // g1_y
                mstore(0x0620, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2) // g2_x_1
                mstore(0x0640, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed) // g2_x_2
                mstore(0x0660, 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b) // g2_y_1
                mstore(0x0680, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa) // g2_y_2
                mstore(0x06a0, 0x186282957db913abd99f91db59fe69922e95040603ef44c0bd7aa3adeef8f5ac) // neg_s_g2_x_1
                mstore(0x06c0, 0x17944351223333f260ddc3b4af45191b856689eda9eab5cbcddbbe570ce860d2) // neg_s_g2_x_2
                mstore(0x06e0, 0x06d971ff4a7467c3ec596ed6efc674572e32fd6f52b721f97e35b0b3d3546753) // neg_s_g2_y_1
                mstore(0x0700, 0x06ecdb9f9567f59ed2eee36e1e1d58797fd13cc97fafc2910f5e8a12f202fa9a) // neg_s_g2_y_2
                mstore(0x0720, 0x17e17b49f6af8ed0070ecee1e189417f300be1952fac4cb107c2be0bbdb1406d) // fixed_comms[0].x
                mstore(0x0740, 0x25c5c81ea46e637663a984a8605cbe4fbb7b5a37a4fbdd131a190a22a2b257c5) // fixed_comms[0].y
                mstore(0x0760, 0x15043e98dbd45b113bea58910734364f6cc54721ecda3851da2b8490cb50d934) // fixed_comms[1].x
                mstore(0x0780, 0x06cc0da7f9328f6500ab1d97b945ca872b83b82cc7239077ad622fe808b312ce) // fixed_comms[1].y
                mstore(0x07a0, 0x1deadd8bd56b5110b36655e8533183fe3084696fa7cc2de4b2f10072046d1b38) // fixed_comms[2].x
                mstore(0x07c0, 0x12e4d52fa859717016fd317899723fd4bdb68f8c9cec0b5b0f8c2256cb77fed5) // fixed_comms[2].y
                mstore(0x07e0, 0x22e75fab2039bac6ddee05e8f3ec1cc5abf035bed19cf2d5e5bb5593bdd5b043) // fixed_comms[3].x
                mstore(0x0800, 0x26424bca11f1ac4d38d675536b1e4df028d6afb0588c2dc9475cecfb46bdd1e7) // fixed_comms[3].y
                mstore(0x0820, 0x0bf5e30b4f8487e05c13b93887b92bc77cb307c0163ffd1a6ddb5dd1940cce4a) // fixed_comms[4].x
                mstore(0x0840, 0x20f553acf33080689762841d5a1f5cc65be3087cf6e8c30cc6f1f5ff766ad779) // fixed_comms[4].y
                mstore(0x0860, 0x04e6e117b976f0ae195efe3cde181b2dfe73361a93cfe7725c9a256bf7d3bbf7) // fixed_comms[5].x
                mstore(0x0880, 0x283978d9c9bd8d385979056c4b4e517061c017ce545f3f6c3918812cd58d938a) // fixed_comms[5].y
                mstore(0x08a0, 0x05b01a8b6d58c1aa1e09c884b9b3af77f56ed9b887504a94c7e07151c5bf1fd8) // fixed_comms[6].x
                mstore(0x08c0, 0x096af5aab9b2bc870bc7f5e7e62ba14e0db82c409506a4da386a0be5a58bd56e) // fixed_comms[6].y
                mstore(0x08e0, 0x228351ad3aa0cb6e1e734fbb96d18a906918a1ef6ee8d76b674797ff4f30751c) // fixed_comms[7].x
                mstore(0x0900, 0x001ec5c050f4f357eeab7fca7cbd46b1a59af901ff74f219e92c1b2fef053d06) // fixed_comms[7].y
                mstore(0x0920, 0x0187bd2495de33d5d3791884167f2518ec2fc25a24a67e089adc7d764e287740) // fixed_comms[8].x
                mstore(0x0940, 0x239901053ed2e8b32941ea95ae44fc188cd17efbaf8f560bb786c03636e31238) // fixed_comms[8].y
                mstore(0x0960, 0x2f970825c1c34524ee63a4c40fb3b1c1988796961b11ef462daec2b456f704c8) // fixed_comms[9].x
                mstore(0x0980, 0x28d22e96844af7baf656e4ad9d2380feebdf4582e0fc35360dfa97d0126d47c5) // fixed_comms[9].y
                mstore(0x09a0, 0x21ea5d386fe018dcc33bdb06ad5555ddd2ac126765821d30eab3ba804613643b) // fixed_comms[10].x
                mstore(0x09c0, 0x060c3c04aab9255969341a32aa54d735709b1da1ac6a0d379bcaee458fe3192c) // fixed_comms[10].y
                mstore(0x09e0, 0x1e321637bb5411c637bd13a2145634568f6eaeb979e20b694e294a082fab5aa9) // fixed_comms[11].x
                mstore(0x0a00, 0x281038a2e4055c27acc0983a10f841321948c78e85c826b530905c90708b7b1b) // fixed_comms[11].y
                mstore(0x0a20, 0x1e983e0a8b3b0c6ab183f27445e938c4798822617f56cabdd6077a8028c3df31) // fixed_comms[12].x
                mstore(0x0a40, 0x0065ebfc146d56c45173a0f656785f2a5295f31be9346b5683d9dc49130ac600) // fixed_comms[12].y
                mstore(0x0a60, 0x09091f724e4a00cacaf8c5b66f6ad3b093bc4c73f429ed99b3d0dfdaff8d6337) // fixed_comms[13].x
                mstore(0x0a80, 0x1ba2971e6abd19c1e17f269714b987c28181ff9e5cc00fcfe7d17bde86bde1de) // fixed_comms[13].y
                mstore(0x0aa0, 0x22abd5f1a0fab7d5544e0e63418e901d6575d3e045bf3b49078060697817127e) // permutation_comms[0].x
                mstore(0x0ac0, 0x156f7efefce3d3949f66bdd09fb38e303bf9783bdefc8c7d8cc2812a9ded3048) // permutation_comms[0].y
                mstore(0x0ae0, 0x2326c8129623441cc22e96f28074bd8491e8ebdab46eb500a49886c923d63591) // permutation_comms[1].x
                mstore(0x0b00, 0x108726a98a6708b685a23cb1601f5796838307cc80c67c3f6a1a5928c8625a80) // permutation_comms[1].y
                mstore(0x0b20, 0x15abf11038d20cc0f44123281b631353cdb04d8c260dd298a0d681121fadad45) // permutation_comms[2].x
                mstore(0x0b40, 0x24f6fce5d238171a855ee9bbb1e9fd0cc9841c25965b681deea327b6767beb55) // permutation_comms[2].y
                mstore(0x0b60, 0x2da9f2b41812b40ac2fb0ef8eba36b8475d3eb04421ece76d8dcc01e672cbaa2) // permutation_comms[3].x
                mstore(0x0b80, 0x0060c5f1673eeefd250f8914fba54f9c643c0d024fa564d6c21fe1aa881239f2) // permutation_comms[3].y
                mstore(0x0ba0, 0x11760652dfbd50e09dc7bcef632637a120d6f4f3b79b35ad1413ecae4c00bfff) // permutation_comms[4].x
                mstore(0x0bc0, 0x1c9760a8b4257425ce110584c0dff41a30aaf03f4bfaaf7e435cb2a69e4d93ad) // permutation_comms[4].y
                mstore(0x0be0, 0x010d4e042cf5c23dbe323091b5fb7ffb33ef8162050c943263d5ecedc46d4ac0) // permutation_comms[5].x
                mstore(0x0c00, 0x06b33af717fc19e3c8debaef2020273249e8705683afc33d5302e5a3581dc7e6) // permutation_comms[5].y

                // Read accumulator from instances
                if mload(HAS_ACCUMULATOR_MPTR) {
                    let num_limbs := mload(NUM_ACC_LIMBS_MPTR)
                    let num_limb_bits := mload(NUM_ACC_LIMB_BITS_MPTR)

                    let cptr := add(INSTANCE_CPTR, mul(mload(ACC_OFFSET_MPTR), 0x20))
                    let lhs_y_off := mul(num_limbs, 0x20)
                    let rhs_x_off := mul(lhs_y_off, 2)
                    let rhs_y_off := mul(lhs_y_off, 3)
                    let lhs_x := calldataload(cptr)
                    let lhs_y := calldataload(add(cptr, lhs_y_off))
                    let rhs_x := calldataload(add(cptr, rhs_x_off))
                    let rhs_y := calldataload(add(cptr, rhs_y_off))
                    for
                        {
                            let cptr_end := add(cptr, mul(0x20, num_limbs))
                            let shift := num_limb_bits
                        }
                        lt(cptr, cptr_end)
                        {}
                    {
                        cptr := add(cptr, 0x20)
                        lhs_x := add(lhs_x, shl(shift, calldataload(cptr)))
                        lhs_y := add(lhs_y, shl(shift, calldataload(add(cptr, lhs_y_off))))
                        rhs_x := add(rhs_x, shl(shift, calldataload(add(cptr, rhs_x_off))))
                        rhs_y := add(rhs_y, shl(shift, calldataload(add(cptr, rhs_y_off))))
                        shift := add(shift, num_limb_bits)
                    }

                    success := and(success, eq(mulmod(lhs_y, lhs_y, q), addmod(mulmod(lhs_x, mulmod(lhs_x, lhs_x, q), q), 3, q)))
                    success := and(success, eq(mulmod(rhs_y, rhs_y, q), addmod(mulmod(rhs_x, mulmod(rhs_x, rhs_x, q), q), 3, q)))

                    mstore(ACC_LHS_X_MPTR, lhs_x)
                    mstore(ACC_LHS_Y_MPTR, lhs_y)
                    mstore(ACC_RHS_X_MPTR, rhs_x)
                    mstore(ACC_RHS_Y_MPTR, rhs_y)
                }

                pop(q)
            }

            // Revert earlier if anything from calldata is invalid
            if iszero(success) {
                revert(0, 0)
            }

            // Compute lagrange evaluations and instance evaluation
            {
                let k := mload(K_MPTR)
                let x := mload(X_MPTR)
                let x_n := x
                for
                    { let idx := 0 }
                    lt(idx, k)
                    { idx := add(idx, 1) }
                {
                    x_n := mulmod(x_n, x_n, r)
                }

                let omega := mload(OMEGA_MPTR)

                let mptr := X_N_MPTR
                let mptr_end := add(mptr, mul(0x20, add(mload(NUM_INSTANCES_MPTR), 6)))
                if iszero(mload(NUM_INSTANCES_MPTR)) {
                    mptr_end := add(mptr_end, 0x20)
                }
                for
                    { let pow_of_omega := mload(OMEGA_INV_TO_L_MPTR) }
                    lt(mptr, mptr_end)
                    { mptr := add(mptr, 0x20) }
                {
                    mstore(mptr, addmod(x, sub(r, pow_of_omega), r))
                    pow_of_omega := mulmod(pow_of_omega, omega, r)
                }
                let x_n_minus_1 := addmod(x_n, sub(r, 1), r)
                mstore(mptr_end, x_n_minus_1)
                success := batch_invert(success, X_N_MPTR, add(mptr_end, 0x20), r)

                mptr := X_N_MPTR
                let l_i_common := mulmod(x_n_minus_1, mload(N_INV_MPTR), r)
                for
                    { let pow_of_omega := mload(OMEGA_INV_TO_L_MPTR) }
                    lt(mptr, mptr_end)
                    { mptr := add(mptr, 0x20) }
                {
                    mstore(mptr, mulmod(l_i_common, mulmod(mload(mptr), pow_of_omega, r), r))
                    pow_of_omega := mulmod(pow_of_omega, omega, r)
                }

                let l_blind := mload(add(X_N_MPTR, 0x20))
                let l_i_cptr := add(X_N_MPTR, 0x40)
                for
                    { let l_i_cptr_end := add(X_N_MPTR, 0xc0) }
                    lt(l_i_cptr, l_i_cptr_end)
                    { l_i_cptr := add(l_i_cptr, 0x20) }
                {
                    l_blind := addmod(l_blind, mload(l_i_cptr), r)
                }

                let instance_eval := 0
                for
                    {
                        let instance_cptr := INSTANCE_CPTR
                        let instance_cptr_end := add(instance_cptr, mul(0x20, mload(NUM_INSTANCES_MPTR)))
                    }
                    lt(instance_cptr, instance_cptr_end)
                    {
                        instance_cptr := add(instance_cptr, 0x20)
                        l_i_cptr := add(l_i_cptr, 0x20)
                    }
                {
                    instance_eval := addmod(instance_eval, mulmod(mload(l_i_cptr), calldataload(instance_cptr), r), r)
                }

                let x_n_minus_1_inv := mload(mptr_end)
                let l_last := mload(X_N_MPTR)
                let l_0 := mload(add(X_N_MPTR, 0xc0))

                mstore(X_N_MPTR, x_n)
                mstore(X_N_MINUS_1_INV_MPTR, x_n_minus_1_inv)
                mstore(L_LAST_MPTR, l_last)
                mstore(L_BLIND_MPTR, l_blind)
                mstore(L_0_MPTR, l_0)
                mstore(INSTANCE_EVAL_MPTR, instance_eval)
            }

            // Compute quotient evavluation
            {
                let quotient_eval_numer
                let delta := 4131629893567559867359510883348571134090853742863529169391034518566172092834
                let y := mload(Y_MPTR)
                {
                    let a_0 := calldataload(0x05e4)
                    let f_0 := calldataload(0x06a4)
                    let var0 := mulmod(a_0, f_0, r)
                    let a_1 := calldataload(0x0604)
                    let f_1 := calldataload(0x06c4)
                    let var1 := mulmod(a_1, f_1, r)
                    let var2 := addmod(var0, var1, r)
                    let a_2 := calldataload(0x0624)
                    let f_2 := calldataload(0x06e4)
                    let var3 := mulmod(a_2, f_2, r)
                    let var4 := addmod(var2, var3, r)
                    let a_3 := calldataload(0x0644)
                    let f_3 := calldataload(0x0704)
                    let var5 := mulmod(a_3, f_3, r)
                    let var6 := addmod(var4, var5, r)
                    let a_4 := calldataload(0x0664)
                    let f_4 := calldataload(0x0724)
                    let var7 := mulmod(a_4, f_4, r)
                    let var8 := addmod(var6, var7, r)
                    let var9 := mulmod(a_0, a_1, r)
                    let f_5 := calldataload(0x0764)
                    let var10 := mulmod(var9, f_5, r)
                    let var11 := addmod(var8, var10, r)
                    let var12 := mulmod(a_2, a_3, r)
                    let f_6 := calldataload(0x0784)
                    let var13 := mulmod(var12, f_6, r)
                    let var14 := addmod(var11, var13, r)
                    let f_7 := calldataload(0x0744)
                    let a_4_next_1 := calldataload(0x0684)
                    let var15 := mulmod(f_7, a_4_next_1, r)
                    let var16 := addmod(var14, var15, r)
                    let f_8 := calldataload(0x07a4)
                    let var17 := addmod(var16, f_8, r)
                    quotient_eval_numer := var17
                }
                {
                    let l_0 := mload(L_0_MPTR)
                    let eval := addmod(l_0, sub(r, mulmod(l_0, calldataload(0x0944), r)), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let perm_z_last := calldataload(0x09a4)
                    let eval := mulmod(mload(L_LAST_MPTR), addmod(mulmod(perm_z_last, perm_z_last, r), sub(r, perm_z_last), r), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let eval := mulmod(mload(L_0_MPTR), addmod(calldataload(0x09a4), sub(r, calldataload(0x0984)), r), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let gamma := mload(GAMMA_MPTR)
                    let beta := mload(BETA_MPTR)
                    let lhs := calldataload(0x0964)
                    let rhs := calldataload(0x0944)
                    lhs := mulmod(lhs, addmod(addmod(calldataload(0x05e4), mulmod(beta, calldataload(0x0884), r), r), gamma, r), r)
                    lhs := mulmod(lhs, addmod(addmod(calldataload(0x0604), mulmod(beta, calldataload(0x08a4), r), r), gamma, r), r)
                    lhs := mulmod(lhs, addmod(addmod(calldataload(0x0624), mulmod(beta, calldataload(0x08c4), r), r), gamma, r), r)
                    mstore(0x00, mulmod(beta, mload(X_MPTR), r))
                    rhs := mulmod(rhs, addmod(addmod(calldataload(0x05e4), mload(0x00), r), gamma, r), r)
                    mstore(0x00, mulmod(mload(0x00), delta, r))
                    rhs := mulmod(rhs, addmod(addmod(calldataload(0x0604), mload(0x00), r), gamma, r), r)
                    mstore(0x00, mulmod(mload(0x00), delta, r))
                    rhs := mulmod(rhs, addmod(addmod(calldataload(0x0624), mload(0x00), r), gamma, r), r)
                    mstore(0x00, mulmod(mload(0x00), delta, r))
                    let left_sub_right := addmod(lhs, sub(r, rhs), r)
                    let eval := addmod(left_sub_right, sub(r, mulmod(left_sub_right, addmod(mload(L_LAST_MPTR), mload(L_BLIND_MPTR), r), r)), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let gamma := mload(GAMMA_MPTR)
                    let beta := mload(BETA_MPTR)
                    let lhs := calldataload(0x09c4)
                    let rhs := calldataload(0x09a4)
                    lhs := mulmod(lhs, addmod(addmod(calldataload(0x0644), mulmod(beta, calldataload(0x08e4), r), r), gamma, r), r)
                    lhs := mulmod(lhs, addmod(addmod(calldataload(0x0664), mulmod(beta, calldataload(0x0904), r), r), gamma, r), r)
                    lhs := mulmod(lhs, addmod(addmod(mload(INSTANCE_EVAL_MPTR), mulmod(beta, calldataload(0x0924), r), r), gamma, r), r)
                    rhs := mulmod(rhs, addmod(addmod(calldataload(0x0644), mload(0x00), r), gamma, r), r)
                    mstore(0x00, mulmod(mload(0x00), delta, r))
                    rhs := mulmod(rhs, addmod(addmod(calldataload(0x0664), mload(0x00), r), gamma, r), r)
                    mstore(0x00, mulmod(mload(0x00), delta, r))
                    rhs := mulmod(rhs, addmod(addmod(mload(INSTANCE_EVAL_MPTR), mload(0x00), r), gamma, r), r)
                    let left_sub_right := addmod(lhs, sub(r, rhs), r)
                    let eval := addmod(left_sub_right, sub(r, mulmod(left_sub_right, addmod(mload(L_LAST_MPTR), mload(L_BLIND_MPTR), r), r)), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_0 := mload(L_0_MPTR)
                    let eval := mulmod(l_0, calldataload(0x09e4), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_last := mload(L_LAST_MPTR)
                    let eval := mulmod(l_last, calldataload(0x09e4), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let theta := mload(THETA_MPTR)
                    let beta := mload(BETA_MPTR)
                    let table
                    {
                        let f_9 := calldataload(0x07c4)
                        let f_10 := calldataload(0x07e4)
                        table := f_9
                        table := addmod(mulmod(table, theta, r), f_10, r)
                        table := addmod(table, beta, r)
                    }
                    let input_0
                    {
                        let f_12 := calldataload(0x0824)
                        let var0 := 0x5
                        let var1 := mulmod(f_12, var0, r)
                        let a_0 := calldataload(0x05e4)
                        let var2 := mulmod(f_12, a_0, r)
                        input_0 := var1
                        input_0 := addmod(mulmod(input_0, theta, r), var2, r)
                        input_0 := addmod(input_0, beta, r)
                    }
                    let lhs
                    let rhs
                    rhs := table
                    {
                        let tmp := input_0
                        rhs := addmod(rhs, sub(r, mulmod(calldataload(0x0a24), tmp, r)), r)
                        lhs := mulmod(mulmod(table, tmp, r), addmod(calldataload(0x0a04), sub(r, calldataload(0x09e4)), r), r)
                    }
                    let eval := mulmod(addmod(1, sub(r, addmod(mload(L_BLIND_MPTR), mload(L_LAST_MPTR), r)), r), addmod(lhs, sub(r, rhs), r), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_0 := mload(L_0_MPTR)
                    let eval := mulmod(l_0, calldataload(0x0a44), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_last := mload(L_LAST_MPTR)
                    let eval := mulmod(l_last, calldataload(0x0a44), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let theta := mload(THETA_MPTR)
                    let beta := mload(BETA_MPTR)
                    let table
                    {
                        let f_9 := calldataload(0x07c4)
                        let f_10 := calldataload(0x07e4)
                        table := f_9
                        table := addmod(mulmod(table, theta, r), f_10, r)
                        table := addmod(table, beta, r)
                    }
                    let input_0
                    {
                        let f_12 := calldataload(0x0824)
                        let var0 := 0x5
                        let var1 := mulmod(f_12, var0, r)
                        let a_1 := calldataload(0x0604)
                        let var2 := mulmod(f_12, a_1, r)
                        input_0 := var1
                        input_0 := addmod(mulmod(input_0, theta, r), var2, r)
                        input_0 := addmod(input_0, beta, r)
                    }
                    let lhs
                    let rhs
                    rhs := table
                    {
                        let tmp := input_0
                        rhs := addmod(rhs, sub(r, mulmod(calldataload(0x0a84), tmp, r)), r)
                        lhs := mulmod(mulmod(table, tmp, r), addmod(calldataload(0x0a64), sub(r, calldataload(0x0a44)), r), r)
                    }
                    let eval := mulmod(addmod(1, sub(r, addmod(mload(L_BLIND_MPTR), mload(L_LAST_MPTR), r)), r), addmod(lhs, sub(r, rhs), r), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_0 := mload(L_0_MPTR)
                    let eval := mulmod(l_0, calldataload(0x0aa4), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_last := mload(L_LAST_MPTR)
                    let eval := mulmod(l_last, calldataload(0x0aa4), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let theta := mload(THETA_MPTR)
                    let beta := mload(BETA_MPTR)
                    let table
                    {
                        let f_9 := calldataload(0x07c4)
                        let f_10 := calldataload(0x07e4)
                        table := f_9
                        table := addmod(mulmod(table, theta, r), f_10, r)
                        table := addmod(table, beta, r)
                    }
                    let input_0
                    {
                        let f_12 := calldataload(0x0824)
                        let var0 := 0x5
                        let var1 := mulmod(f_12, var0, r)
                        let a_2 := calldataload(0x0624)
                        let var2 := mulmod(f_12, a_2, r)
                        input_0 := var1
                        input_0 := addmod(mulmod(input_0, theta, r), var2, r)
                        input_0 := addmod(input_0, beta, r)
                    }
                    let lhs
                    let rhs
                    rhs := table
                    {
                        let tmp := input_0
                        rhs := addmod(rhs, sub(r, mulmod(calldataload(0x0ae4), tmp, r)), r)
                        lhs := mulmod(mulmod(table, tmp, r), addmod(calldataload(0x0ac4), sub(r, calldataload(0x0aa4)), r), r)
                    }
                    let eval := mulmod(addmod(1, sub(r, addmod(mload(L_BLIND_MPTR), mload(L_LAST_MPTR), r)), r), addmod(lhs, sub(r, rhs), r), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_0 := mload(L_0_MPTR)
                    let eval := mulmod(l_0, calldataload(0x0b04), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_last := mload(L_LAST_MPTR)
                    let eval := mulmod(l_last, calldataload(0x0b04), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let theta := mload(THETA_MPTR)
                    let beta := mload(BETA_MPTR)
                    let table
                    {
                        let f_9 := calldataload(0x07c4)
                        let f_10 := calldataload(0x07e4)
                        table := f_9
                        table := addmod(mulmod(table, theta, r), f_10, r)
                        table := addmod(table, beta, r)
                    }
                    let input_0
                    {
                        let f_12 := calldataload(0x0824)
                        let var0 := 0x5
                        let var1 := mulmod(f_12, var0, r)
                        let a_3 := calldataload(0x0644)
                        let var2 := mulmod(f_12, a_3, r)
                        input_0 := var1
                        input_0 := addmod(mulmod(input_0, theta, r), var2, r)
                        input_0 := addmod(input_0, beta, r)
                    }
                    let lhs
                    let rhs
                    rhs := table
                    {
                        let tmp := input_0
                        rhs := addmod(rhs, sub(r, mulmod(calldataload(0x0b44), tmp, r)), r)
                        lhs := mulmod(mulmod(table, tmp, r), addmod(calldataload(0x0b24), sub(r, calldataload(0x0b04)), r), r)
                    }
                    let eval := mulmod(addmod(1, sub(r, addmod(mload(L_BLIND_MPTR), mload(L_LAST_MPTR), r)), r), addmod(lhs, sub(r, rhs), r), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_0 := mload(L_0_MPTR)
                    let eval := mulmod(l_0, calldataload(0x0b64), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let l_last := mload(L_LAST_MPTR)
                    let eval := mulmod(l_last, calldataload(0x0b64), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }
                {
                    let theta := mload(THETA_MPTR)
                    let beta := mload(BETA_MPTR)
                    let table
                    {
                        let f_9 := calldataload(0x07c4)
                        let f_10 := calldataload(0x07e4)
                        table := f_9
                        table := addmod(mulmod(table, theta, r), f_10, r)
                        table := addmod(table, beta, r)
                    }
                    let input_0
                    {
                        let f_11 := calldataload(0x0804)
                        let f_13 := calldataload(0x0844)
                        let a_0 := calldataload(0x05e4)
                        let var0 := mulmod(f_13, a_0, r)
                        input_0 := f_11
                        input_0 := addmod(mulmod(input_0, theta, r), var0, r)
                        input_0 := addmod(input_0, beta, r)
                    }
                    let lhs
                    let rhs
                    rhs := table
                    {
                        let tmp := input_0
                        rhs := addmod(rhs, sub(r, mulmod(calldataload(0x0ba4), tmp, r)), r)
                        lhs := mulmod(mulmod(table, tmp, r), addmod(calldataload(0x0b84), sub(r, calldataload(0x0b64)), r), r)
                    }
                    let eval := mulmod(addmod(1, sub(r, addmod(mload(L_BLIND_MPTR), mload(L_LAST_MPTR), r)), r), addmod(lhs, sub(r, rhs), r), r)
                    quotient_eval_numer := addmod(mulmod(quotient_eval_numer, y, r), eval, r)
                }

                pop(y)
                pop(delta)

                let quotient_eval := mulmod(quotient_eval_numer, mload(X_N_MINUS_1_INV_MPTR), r)
                mstore(QUOTIENT_EVAL_MPTR, quotient_eval)
            }

            // Compute quotient commitment
            {
                mstore(0x00, calldataload(LAST_QUOTIENT_X_CPTR))
                mstore(0x20, calldataload(add(LAST_QUOTIENT_X_CPTR, 0x20)))
                let x_n := mload(X_N_MPTR)
                for
                    {
                        let cptr := sub(LAST_QUOTIENT_X_CPTR, 0x40)
                        let cptr_end := sub(FIRST_QUOTIENT_X_CPTR, 0x40)
                    }
                    lt(cptr_end, cptr)
                    {}
                {
                    success := ec_mul_acc(success, x_n)
                    success := ec_add_acc(success, calldataload(cptr), calldataload(add(cptr, 0x20)))
                    cptr := sub(cptr, 0x40)
                }
                mstore(QUOTIENT_X_MPTR, mload(0x00))
                mstore(QUOTIENT_Y_MPTR, mload(0x20))
            }

            // Compute pairing lhs and rhs
            {
                {
                    let x := mload(X_MPTR)
                    let omega := mload(OMEGA_MPTR)
                    let omega_inv := mload(OMEGA_INV_MPTR)
                    let x_pow_of_omega := mulmod(x, omega, r)
                    mstore(0x02c0, x_pow_of_omega)
                    mstore(0x02a0, x)
                    x_pow_of_omega := mulmod(x, omega_inv, r)
                    x_pow_of_omega := mulmod(x_pow_of_omega, omega_inv, r)
                    x_pow_of_omega := mulmod(x_pow_of_omega, omega_inv, r)
                    x_pow_of_omega := mulmod(x_pow_of_omega, omega_inv, r)
                    x_pow_of_omega := mulmod(x_pow_of_omega, omega_inv, r)
                    x_pow_of_omega := mulmod(x_pow_of_omega, omega_inv, r)
                    mstore(0x0280, x_pow_of_omega)
                }
                {
                    let mu := mload(MU_MPTR)
                    for
                        {
                            let mptr := 0x02e0
                            let mptr_end := 0x0340
                            let point_mptr := 0x0280
                        }
                        lt(mptr, mptr_end)
                        {
                            mptr := add(mptr, 0x20)
                            point_mptr := add(point_mptr, 0x20)
                        }
                    {
                        mstore(mptr, addmod(mu, sub(r, mload(point_mptr)), r))
                    }
                    let s
                    s := mload(0x0300)
                    mstore(0x0340, s)
                    let diff
                    diff := mload(0x02e0)
                    diff := mulmod(diff, mload(0x0320), r)
                    mstore(0x0360, diff)
                    mstore(0x00, diff)
                    diff := mload(0x02e0)
                    mstore(0x0380, diff)
                    diff := 1
                    mstore(0x03a0, diff)
                }
                {
                    let point_1 := mload(0x02a0)
                    let coeff
                    coeff := 1
                    coeff := mulmod(coeff, mload(0x0300), r)
                    mstore(0x20, coeff)
                }
                {
                    let point_1 := mload(0x02a0)
                    let point_2 := mload(0x02c0)
                    let coeff
                    coeff := addmod(point_1, sub(r, point_2), r)
                    coeff := mulmod(coeff, mload(0x0300), r)
                    mstore(0x40, coeff)
                    coeff := addmod(point_2, sub(r, point_1), r)
                    coeff := mulmod(coeff, mload(0x0320), r)
                    mstore(0x60, coeff)
                }
                {
                    let point_0 := mload(0x0280)
                    let point_1 := mload(0x02a0)
                    let point_2 := mload(0x02c0)
                    let coeff
                    coeff := addmod(point_0, sub(r, point_1), r)
                    coeff := mulmod(coeff, addmod(point_0, sub(r, point_2), r), r)
                    coeff := mulmod(coeff, mload(0x02e0), r)
                    mstore(0x80, coeff)
                    coeff := addmod(point_1, sub(r, point_0), r)
                    coeff := mulmod(coeff, addmod(point_1, sub(r, point_2), r), r)
                    coeff := mulmod(coeff, mload(0x0300), r)
                    mstore(0xa0, coeff)
                    coeff := addmod(point_2, sub(r, point_0), r)
                    coeff := mulmod(coeff, addmod(point_2, sub(r, point_1), r), r)
                    coeff := mulmod(coeff, mload(0x0320), r)
                    mstore(0xc0, coeff)
                }
                {
                    success := batch_invert(success, 0, 0xe0, r)
                    let diff_0_inv := mload(0x00)
                    mstore(0x0360, diff_0_inv)
                    for
                        {
                            let mptr := 0x0380
                            let mptr_end := 0x03c0
                        }
                        lt(mptr, mptr_end)
                        { mptr := add(mptr, 0x20) }
                    {
                        mstore(mptr, mulmod(mload(mptr), diff_0_inv, r))
                    }
                }
                {
                    let coeff := mload(0x20)
                    let zeta := mload(ZETA_MPTR)
                    let r_eval := 0
                    r_eval := addmod(r_eval, mulmod(coeff, calldataload(0x0864), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(coeff, mload(QUOTIENT_EVAL_MPTR), r), r)
                    for
                        {
                            let mptr := 0x0924
                            let mptr_end := 0x0864
                        }
                        lt(mptr_end, mptr)
                        { mptr := sub(mptr, 0x20) }
                    {
                        r_eval := addmod(mulmod(r_eval, zeta, r), mulmod(coeff, calldataload(mptr), r), r)
                    }
                    for
                        {
                            let mptr := 0x0844
                            let mptr_end := 0x0684
                        }
                        lt(mptr_end, mptr)
                        { mptr := sub(mptr, 0x20) }
                    {
                        r_eval := addmod(mulmod(r_eval, zeta, r), mulmod(coeff, calldataload(mptr), r), r)
                    }
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(coeff, calldataload(0x0ba4), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(coeff, calldataload(0x0b44), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(coeff, calldataload(0x0ae4), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(coeff, calldataload(0x0a84), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(coeff, calldataload(0x0a24), r), r)
                    for
                        {
                            let mptr := 0x0644
                            let mptr_end := 0x05c4
                        }
                        lt(mptr_end, mptr)
                        { mptr := sub(mptr, 0x20) }
                    {
                        r_eval := addmod(mulmod(r_eval, zeta, r), mulmod(coeff, calldataload(mptr), r), r)
                    }
                    mstore(0x03c0, r_eval)
                }
                {
                    let zeta := mload(ZETA_MPTR)
                    let r_eval := 0
                    r_eval := addmod(r_eval, mulmod(mload(0x40), calldataload(0x0b64), r), r)
                    r_eval := addmod(r_eval, mulmod(mload(0x60), calldataload(0x0b84), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(mload(0x40), calldataload(0x0b04), r), r)
                    r_eval := addmod(r_eval, mulmod(mload(0x60), calldataload(0x0b24), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(mload(0x40), calldataload(0x0aa4), r), r)
                    r_eval := addmod(r_eval, mulmod(mload(0x60), calldataload(0x0ac4), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(mload(0x40), calldataload(0x0a44), r), r)
                    r_eval := addmod(r_eval, mulmod(mload(0x60), calldataload(0x0a64), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(mload(0x40), calldataload(0x09e4), r), r)
                    r_eval := addmod(r_eval, mulmod(mload(0x60), calldataload(0x0a04), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(mload(0x40), calldataload(0x09a4), r), r)
                    r_eval := addmod(r_eval, mulmod(mload(0x60), calldataload(0x09c4), r), r)
                    r_eval := mulmod(r_eval, zeta, r)
                    r_eval := addmod(r_eval, mulmod(mload(0x40), calldataload(0x0664), r), r)
                    r_eval := addmod(r_eval, mulmod(mload(0x60), calldataload(0x0684), r), r)
                    r_eval := mulmod(r_eval, mload(0x0380), r)
                    mstore(0x03e0, r_eval)
                }
                {
                    let zeta := mload(ZETA_MPTR)
                    let r_eval := 0
                    r_eval := addmod(r_eval, mulmod(mload(0x80), calldataload(0x0984), r), r)
                    r_eval := addmod(r_eval, mulmod(mload(0xa0), calldataload(0x0944), r), r)
                    r_eval := addmod(r_eval, mulmod(mload(0xc0), calldataload(0x0964), r), r)
                    r_eval := mulmod(r_eval, mload(0x03a0), r)
                    mstore(0x0400, r_eval)
                }
                {
                    let sum := mload(0x20)
                    mstore(0x0420, sum)
                }
                {
                    let sum := mload(0x40)
                    sum := addmod(sum, mload(0x60), r)
                    mstore(0x0440, sum)
                }
                {
                    let sum := mload(0x80)
                    sum := addmod(sum, mload(0xa0), r)
                    sum := addmod(sum, mload(0xc0), r)
                    mstore(0x0460, sum)
                }
                {
                    for
                        {
                            let mptr := 0x00
                            let mptr_end := 0x60
                            let sum_mptr := 0x0420
                        }
                        lt(mptr, mptr_end)
                        {
                            mptr := add(mptr, 0x20)
                            sum_mptr := add(sum_mptr, 0x20)
                        }
                    {
                        mstore(mptr, mload(sum_mptr))
                    }
                    success := batch_invert(success, 0, 0x60, r)
                    let r_eval := mulmod(mload(0x40), mload(0x0400), r)
                    for
                        {
                            let sum_inv_mptr := 0x20
                            let sum_inv_mptr_end := 0x60
                            let r_eval_mptr := 0x03e0
                        }
                        lt(sum_inv_mptr, sum_inv_mptr_end)
                        {
                            sum_inv_mptr := sub(sum_inv_mptr, 0x20)
                            r_eval_mptr := sub(r_eval_mptr, 0x20)
                        }
                    {
                        r_eval := mulmod(r_eval, mload(NU_MPTR), r)
                        r_eval := addmod(r_eval, mulmod(mload(sum_inv_mptr), mload(r_eval_mptr), r), r)
                    }
                    mstore(R_EVAL_MPTR, r_eval)
                }
                {
                    let nu := mload(NU_MPTR)
                    mstore(0x00, calldataload(0x04a4))
                    mstore(0x20, calldataload(0x04c4))
                    success := ec_mul_acc(success, mload(ZETA_MPTR))
                    success := ec_add_acc(success, mload(QUOTIENT_X_MPTR), mload(QUOTIENT_Y_MPTR))
                    for
                        {
                            let mptr := 0x0be0
                            let mptr_end := 0x08e0
                        }
                        lt(mptr_end, mptr)
                        { mptr := sub(mptr, 0x40) }
                    {
                        success := ec_mul_acc(success, mload(ZETA_MPTR))
                        success := ec_add_acc(success, mload(mptr), mload(add(mptr, 0x20)))
                    }
                    success := ec_mul_acc(success, mload(ZETA_MPTR))
                    success := ec_add_acc(success, mload(0x08a0), mload(0x08c0))
                    success := ec_mul_acc(success, mload(ZETA_MPTR))
                    success := ec_add_acc(success, mload(0x0860), mload(0x0880))
                    success := ec_mul_acc(success, mload(ZETA_MPTR))
                    success := ec_add_acc(success, mload(0x08e0), mload(0x0900))
                    for
                        {
                            let mptr := 0x0820
                            let mptr_end := 0x06e0
                        }
                        lt(mptr_end, mptr)
                        { mptr := sub(mptr, 0x40) }
                    {
                        success := ec_mul_acc(success, mload(ZETA_MPTR))
                        success := ec_add_acc(success, mload(mptr), mload(add(mptr, 0x20)))
                    }
                    for
                        {
                            let mptr := 0x02a4
                            let mptr_end := 0x0164
                        }
                        lt(mptr_end, mptr)
                        { mptr := sub(mptr, 0x40) }
                    {
                        success := ec_mul_acc(success, mload(ZETA_MPTR))
                        success := ec_add_acc(success, calldataload(mptr), calldataload(add(mptr, 0x20)))
                    }
                    for
                        {
                            let mptr := 0x0124
                            let mptr_end := 0x24
                        }
                        lt(mptr_end, mptr)
                        { mptr := sub(mptr, 0x40) }
                    {
                        success := ec_mul_acc(success, mload(ZETA_MPTR))
                        success := ec_add_acc(success, calldataload(mptr), calldataload(add(mptr, 0x20)))
                    }
                    mstore(0x80, calldataload(0x0464))
                    mstore(0xa0, calldataload(0x0484))
                    for
                        {
                            let mptr := 0x0424
                            let mptr_end := 0x02e4
                        }
                        lt(mptr_end, mptr)
                        { mptr := sub(mptr, 0x40) }
                    {
                        success := ec_mul_tmp(success, mload(ZETA_MPTR))
                        success := ec_add_tmp(success, calldataload(mptr), calldataload(add(mptr, 0x20)))
                    }
                    success := ec_mul_tmp(success, mload(ZETA_MPTR))
                    success := ec_add_tmp(success, calldataload(0x0164), calldataload(0x0184))
                    success := ec_mul_tmp(success, mulmod(nu, mload(0x0380), r))
                    success := ec_add_acc(success, mload(0x80), mload(0xa0))
                    nu := mulmod(nu, mload(NU_MPTR), r)
                    mstore(0x80, calldataload(0x02e4))
                    mstore(0xa0, calldataload(0x0304))
                    success := ec_mul_tmp(success, mulmod(nu, mload(0x03a0), r))
                    success := ec_add_acc(success, mload(0x80), mload(0xa0))
                    mstore(0x80, mload(G1_X_MPTR))
                    mstore(0xa0, mload(G1_Y_MPTR))
                    success := ec_mul_tmp(success, sub(r, mload(R_EVAL_MPTR)))
                    success := ec_add_acc(success, mload(0x80), mload(0xa0))
                    mstore(0x80, calldataload(0x0bc4))
                    mstore(0xa0, calldataload(0x0be4))
                    success := ec_mul_tmp(success, sub(r, mload(0x0340)))
                    success := ec_add_acc(success, mload(0x80), mload(0xa0))
                    mstore(0x80, calldataload(0x0c04))
                    mstore(0xa0, calldataload(0x0c24))
                    success := ec_mul_tmp(success, mload(MU_MPTR))
                    success := ec_add_acc(success, mload(0x80), mload(0xa0))
                    mstore(PAIRING_LHS_X_MPTR, mload(0x00))
                    mstore(PAIRING_LHS_Y_MPTR, mload(0x20))
                    mstore(PAIRING_RHS_X_MPTR, calldataload(0x0c04))
                    mstore(PAIRING_RHS_Y_MPTR, calldataload(0x0c24))
                }
            }

            // Random linear combine with accumulator
            if mload(HAS_ACCUMULATOR_MPTR) {
                mstore(0x00, mload(ACC_LHS_X_MPTR))
                mstore(0x20, mload(ACC_LHS_Y_MPTR))
                mstore(0x40, mload(ACC_RHS_X_MPTR))
                mstore(0x60, mload(ACC_RHS_Y_MPTR))
                mstore(0x80, mload(PAIRING_LHS_X_MPTR))
                mstore(0xa0, mload(PAIRING_LHS_Y_MPTR))
                mstore(0xc0, mload(PAIRING_RHS_X_MPTR))
                mstore(0xe0, mload(PAIRING_RHS_Y_MPTR))
                let challenge := mod(keccak256(0x00, 0x100), r)

                // [pairing_lhs] += challenge * [acc_lhs]
                success := ec_mul_acc(success, challenge)
                success := ec_add_acc(success, mload(PAIRING_LHS_X_MPTR), mload(PAIRING_LHS_Y_MPTR))
                mstore(PAIRING_LHS_X_MPTR, mload(0x00))
                mstore(PAIRING_LHS_Y_MPTR, mload(0x20))

                // [pairing_rhs] += challenge * [acc_rhs]
                mstore(0x00, mload(ACC_RHS_X_MPTR))
                mstore(0x20, mload(ACC_RHS_Y_MPTR))
                success := ec_mul_acc(success, challenge)
                success := ec_add_acc(success, mload(PAIRING_RHS_X_MPTR), mload(PAIRING_RHS_Y_MPTR))
                mstore(PAIRING_RHS_X_MPTR, mload(0x00))
                mstore(PAIRING_RHS_Y_MPTR, mload(0x20))
            }

            // Perform pairing
            success := ec_pairing(
                success,
                mload(PAIRING_LHS_X_MPTR),
                mload(PAIRING_LHS_Y_MPTR),
                mload(PAIRING_RHS_X_MPTR),
                mload(PAIRING_RHS_Y_MPTR)
            )

            // Revert if anything fails
            if iszero(success) {
                revert(0x00, 0x00)
            }

            // Return 1 as result if everything succeeds
            mstore(0x00, 1)
            return(0x00, 0x20)
        }
    }
}