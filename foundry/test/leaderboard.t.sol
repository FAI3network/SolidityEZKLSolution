// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Halo2Verifier} from "../src/Verifier.sol";
import {Leaderboard} from "../src/Leaderboard.sol";
import {IVerifier} from "../src/IVerifier.sol";
import {ILeaderboard} from "../src/ILeaderboard.sol";
import {Utils} from "../utils/Utils.sol";

contract leaderboardTest is Test {
    Halo2Verifier public haloVf;
    Leaderboard public lb;
    IVerifier public verifier;
    Utils public utils;

    /* Errors */
    error ModelAlreadyRegistered();
    error ModelNotRegistered();
    error InferenceAlreadyVerified();
    error InvalidProof();
    error NotProver();
    error NotOwner();
    error InferenceAlreadyChecked();
    error InferenceNotExists();

    /* Events */
    event ModelRegistered(IVerifier indexed verifier, address indexed owner);
    event ModelDeleted(IVerifier indexed verifier, address indexed owner);
    event InferenceVerified(
        IVerifier indexed verifier,
        bytes indexed proof,
        uint256[] instances,
        address indexed prover
    );
    event MetricsRun(
        IVerifier indexed verifier,
        uint256[] metrics,
        bytes32 indexed nullifier
    );

    /* Constants */
    string constant MODEL_URI =
        "data:application/json;base64,ewogICJuYW1lIjogIkNyZWRpdCBTY29yaW5nIFhnYm9vc3QgTW9kZWwiLAogICJkZXNjcmlwdGlvbiI6ICJBbiBYZ2Jvb3N0LWJhc2VkIG1hY2hpbmUgbGVhcm5pbmcgbW9kZWwgZm9yIGNyZWRpdCBzY29yaW5nIGFwcGxpY2F0aW9ucy4iLAogICJpbWFnZVVSTCI6ICJodHRwczovL2V4YW1wbGUuY29tL2NyZWRpdF9zY29yaW5nX3hnYm9vc3QucG5nIiwKICAic2l6ZSI6ICIxMjBNQiIsCiAgImFjY3VyYWN5IjogIjAuNzgiLAogICJmcmFtZXdvcmsiOiAiWGdib29zdCIsCiAgInZlcnNpb24iOiAiMS40LjAiLAogICJoeXBlcnBhcmFtZXRlcnMiOiB7CiAgICAibWF4X2RlcHRoIjogNSwKICAgICJsZWFybmluZ19yYXRlIjogMC4wNSwKICAgICJuX2VzdGltYXRvcnMiOiAyMDAsCiAgICAib2JqZWN0aXZlIjogImJpbmFyeTpsb2dpc3RpYyIKICB9LAogICJkYXRhc2V0X3VzZWQiOiAiQ3JlZGl0U2NvcmluZ0RhdGFzZXQgdjMuMSIsCiAgInRyYWluZWRfb24iOiAiTlZJRElBIFRlc2xhIFYxMDAgR1BVIiwKICAiZGVwbG95ZWRfd2l0aCI6ICJLdWJlcm5ldGVzIGNsdXN0ZXIiLAogICJjcmVhdGVkX2J5IjogIkZpbmFuY2VNTENvIiwKICAiZGF0ZV9jcmVhdGVkIjogIjIwMjMtMTAtMTUiCn0";
    string constant I_PROOF =
        "0x16c587d9a7fee77b2ee5ce7041d417dc6f9dbf471b1583ee0bc0caa42fda49c2050bf5a978b02b1e6826c928fcecc22c3821c8e672fa16b1edb4fb3f44b2e93d2b25b9194252ad00856cb5a945c46e2259f2d75bac3817fc33924060a80707ae202cae6f2a669aa4aa57180d7270835535aab6daf5d4b4f8fdc63161990406922cbbcca4a38b1641016144b5e298a18da70c0c14d405e9dcf78f9a782f5ae19e1bb5cc2378cd86ded0d651bd4ea6917910ac4f21f4fb5eacc00838898bd73027156ae4ab4b5d5edc1cfb07f74d725a9502607d9740e3b527686a1d34d40b64ab0580d7b5298c15d142fb7f66d826663cf0f961e81828c423943a3a4de6b64ba42a33730278fe39477507dba17dd34de2f68017a5d8e82961887f541591eeb7e425d2a62671d93be7fb804554e0836925f7638f90ebe347b4cd908d313520457f0982efe6c682fb79d868c897edd93a2cc5e2cc00293fde41b5715be7f6c9858d1eb36fa25e67f6c9adf7425221c490df66fcfec83c729f9774ddaf908d5f78ea1fbf8ba0a2c95858a4970e299aa76b57c70ef453bb9d820cd8794f7fc2bedeb81c13221094adb40fcdfc5a4fb8499fac3f0afa872a305d165f5cef6c80123127289b542d6e75669443ebf7e459fde6e4848d3faa0d553ade26f37443d7f5cbbd088b3a51d72951918ecaf73006a3143bf424babf5d766bd23eb6d799fc4561c4045cb14c1f777e45a075e32a5130579baca933c03e66a12c904fabbb932d53142a84911a847fbfee082c8710a40c0d1c0cca5d84b4c367c7ccf5d8aa60a2f9fc1ab27c11d0ccce52b709624cb2aa571310b31ab46a4fbb934dfe4ab53718173d2066f2fba58f9687c2f7e81d5edec3922b443145a38fd897066f3ad4afb80338230619c9f03fe4acb862df8468ff3a1126d298e74e019b596900796827a7c1551d24e97f3922adde9eb7712e0a79c7433432106515df96edc0ee99bf667a2a7e1edfa93bd0a16f00018e4ed1d388f107ca80d5c21e9b066320a9f4c58c7f29e408705b47fc10a26fb39c06bd5960aed0c7ca2ebd8b457776e4d7eb41403d58320f9c1132b7e79665751c950e1ddcb6f134c50e21a9504f34743eaad849d3c9a8228b0b5add89398e46dca11e136fbd23d10e1557ed9b1c34f819a51888e4c9bc2d626d5205daf1214e058b763b3a1f2f6dd25296ec90c9e2a34ba4c38cc9b5340a6d1853ed4136ecd28eb050b7f7a339c47dcc9de3350c570b39d98c3bdccf82128e9c0a224184102324f9ce4108c2eeafb4b9aa3e2a294114b0cc47a3aa809401cabfe15bb2fd2021412a02d4fd68a5271834ba5115bb1f4502a0861cf8c2e0262d2b6c01cb11c1287b1521ecf972fa8d63c101401685a427eda40a5ba05a661888d8e20301be621fd95987e6d7234f9f115d6b587b74fbfd35d51a3d4ff5231d9da74ff0099b69431a9c2c2d8fe1453409ab797871e672d562b7a2e09b3490220c7e6bff29f01680cecee3533e406691100f9f061fc0bef9b9acd77d4afcf01766cbc55ee172ee37221119bad4d17b879cd51755534de66606ab074be86e6716a52c93bbf0b60866367520788891192221840d7068dfdee9cacdd7c75cef172df523618756b139cca5a6b8a6bc9aadee629a2f24d8e7bef48ebea5341dc6731dad65f2bf4175cddf5c187d7db47827a3b3d1f2e6a4f89423dc3fed6ec6f90225f287c8aee3fa61c0c687ca07994611d4ded973a6459aeb0d54b0d470c532881aab411d3ca93cb2d8c345900345ca2d64e8f0b57e246978648378a35b30242c0457efb669d310fc8315242830eaa489b739cf2b8357eded0035be770c98869509f48a75819f3c1954725ed42a041b40261678fdd7fb5abeaaedc0557ccc655d1b33743f34ef20fa22e4ea8ad8837af8f96d8dc7ebb177fe13e793d6061e0beb2e8179267dd5b2148b70fc9d51f1cb2b9de33bc8c1ceaa4957ad2b90dbaf205e18652a7149444f40b42f000ee5c6ba8512f08ef04806af2a36c9a69b455849fb013bc9771b5e0a4e182d2a19aabb9a1f6e100c3cfb1c5413590e7329b1d48a291699657b466181b92f3f3e43102e0ba7071a39ddc1532c4f2dc1d669082e9f310805aee637ceff9b66f84b2ac18e788d981c57f0f20c8051a95bc4d0ed250ec62ca0ea13b9b8512854c48ba846ea28644ac463d381b6fba0c909f5e2bb66fc8e26288bf23b369959b1282d443e368ba2bc1158b6a8ebcbd377e6773d16b5982126015580c0c59fbfa7891a3fe6176428cbf8f58940c07e2614a6ec0fdafe14f4160ee0c41dca3a4eb723b31236bbc7f4dc04de0ffb852dd3a750ce883e092f0125c6dea511d469f39ae1c7e22d733e817df70ad991f47318a65487446512e1ab169b54aad3a847ed4baba8535647c4b9eb60a24850f2022d04d6d9bce94e4aff2c2fa0953feb8eb3e01413691995b5aee584ce8f37e22c442eeb6a98ca375cc20c2e33df2d7b3979c5936c8138176e8865f0eeb4b2fbe116e5b1ac3c896f7d0b0709334c412ce543649c5c22b0f9d27cc71a42d2419e1671e68c9b366aec89650a878190d48b43ad45feee0b1684a617bb27c68ae426317ea077c96029bac9cc088ce3f5333a8e1b5f783149772818d04142a5a47528f7fe753c38843bd9eec41be130fe18e99d9cf427e1dfcfd9b27c21c7faa588949640aee0ede94878452c23be27a36b4b70c86dab472edca5d4e7a3f50f1417a41fd90596e351d2a2a443112ddbef7f0ab7f86aac6d76110fac369a88a7b01af23ad9fe8b1e83d0ffdd8b272f3456f93485188d7a7b0e1d4d487eb25bfa52be24899ce3c27156c8dee40d000000000000000000000000000000000000000000000000000000000000000000c1f8ea084d1fd50421ec47a0fbe0fd8d04a4dd3575b37f70d83e5910fcfef619a6f4414acce076b07f2c42b2f842513b036990f9d1a35514d2d746bb4441c82eef8638fe556369dad9e6aaba287eedb8710acff1ae9c4408b6a416c348d43a1841e3f99e6031adb30e2912b315700defe6033ba411d88d932d93b353a742cf01c44b412309a155378fefc33994ca7a5d10682d5cafc1b75c25822cf2a6d2920ece99d0d76c208c13e2ce947c8562a770f14c26987c22e47b2970e7d61b49821aac79a241784db4329539991255e8202387975d77706621ff509e2f19b88dde074810b1e0bdae51c5e37d6b1b349b8bc2e7e9f03f99ac7aa1a7566966fe20c626bf8da92b4efacf0587bbc4c076a7612991f582ded614e0c88fbb52741bcb58068b329fc9162847188bc177ac5cfe6bfaf8c906bc7d04b3a71871bad7cea99c05a0053b70bfd5d8ff2ebc70acdf1e8cea2202389efde7466b7b95cb850c033627d871dd686512f9a9ad3b2494591c527905aff6f3ece2594c893c08f7c5265e0c2ca3f6387e2c1f3b8446ca6c1f9fc355fdd25a190254184825b76265fc70d103fee68b6dacb2fd52d64db18bde5ed1896d74de407db7ea0e3fb4880d316d4b009f8534f49675f0a1a53493e6998648eae86eb33bca574c0cb3ef48a683b8302f3ff6a97bdbe60d7405f8737685b0b7a6af17e6a53683b969be3a60347d58b42ed866b9f50f4a6086f7732f02d6545e626592e2de79f363f2a593ed628471eb151a371652a05a370b579773a4eb4f19e7fdaebb3843ee97ec16eecedda8f801187a9a4b35f8ed949b75032ee5e217f6d4720b88dd634ea1b8c00b5ce8075b0a2b0a0471ff15551284a5b92cc7ceef1f725850a969aa2a01eeeee4ed6b021600089c51c3a57035e6fbfb5ed29586590592a272f8f9cdaf645fe725e88951350e1fd660dd5c0ffb10e0ca117fb8455c2e0d41b7f645f0fb07b0530de37107f1362cb623d45564ba2cb07cc9f9014cf339f9ebe18ae2d6f625fefa5790ac28c0580317b85f80143a383afc5fcfe3b35e61b2e0b6834e1c42b65ab88e604c6b33431fe2da7bc69450242e00c69a290e1460ee66945af5632947a348e68a02bdb88515f30429783a06866e6d4a351e22b63c1759c863b30dada2d60cf1c2d514ae71272ff14cd1211b73c33a3bd21120c86ba9c9967fe39097d960a049a85bc327581ce8e66406d5c209742b4f6c0b5ca96139d341fb752f6b483b9f5fa29dfc8a9f2aef46262ac37bb3a4a783970dd382c3b4192682d63137262e80189321f8f48426f671e2fc118226776e764f21c1dfe933f8dd309c0143eb0fe8c993477bc4a828d7852ff6cd28750058cf45777543cf65652b7bead57b78d7152244d0e3893f2cf4573560e6a529c2d583a54dc57de7e029d81cd3054ffa17fd8cad2843369810f29cc4a28cc51188bb5039f07971fe45d423426fc51016297d54e02875b609";
    string[] public I_INST;

    /* Tests */
    function setUp() public {
        lb = new Leaderboard();
        haloVf = new Halo2Verifier();
        verifier = IVerifier(address(haloVf));
        utils = new Utils();
        I_INST = [
            "0x0000000000000000000000000000000000000000000000000000000000000101",
            "0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffe14",
            "0x000000000000000000000000000000000000000000000000000000000000014a",
            "0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffde7",
            "0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffe5a",
            "0x0000000000000000000000000000000000000000000000000000000000000179",
            "0x0000000000000000000000000000000000000000000000000000000000000165",
            "0x00000000000000000000000000000000000000000000000000000000000002d7",
            "0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffe22",
            "0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffeb1"
        ];
    }

    /* Test registerModel */
    function test_registerModel() public {
        vm.expectEmit();
        emit ModelRegistered(verifier, address(this));
        lb.registerModel(verifier, MODEL_URI);
        (address owner, string memory modelURI) = lb.getModel(
            address(verifier)
        );
        assertTrue(owner == address(this));
        assertTrue(
            keccak256(abi.encodePacked(modelURI)) ==
                keccak256(abi.encodePacked(MODEL_URI))
        );
    }

    function test_alreadyRegistered() public {
        lb.registerModel(verifier, MODEL_URI);

        vm.expectRevert(
            abi.encodeWithSelector(ModelAlreadyRegistered.selector)
        );
        lb.registerModel(verifier, MODEL_URI);
    }

    /* Test deleteModel */
    function test_deleteModel() public {
        this.test_registerModel();
        vm.expectEmit();
        emit ModelDeleted(verifier, address(this));
        lb.deleteModel(verifier);
        (address owner, string memory tokenURI) = lb.getModel(
            address(verifier)
        );
        assertTrue(owner == address(0));
        assertTrue(bytes(tokenURI).length == 0);
    }

    function test_deleteModelNotRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(ModelNotRegistered.selector));
        lb.deleteModel(verifier);
    }

    function test_isNotOwner() public {
        this.test_registerModel();
        vm.startPrank(makeAddr("random"));
        vm.expectRevert(abi.encodeWithSelector(NotOwner.selector));
        lb.deleteModel(verifier);
        vm.stopPrank();
    }

    /* Test verifyInference */

    function test_verifyInference() public returns (bytes32) {
        this.test_registerModel();

        bytes memory proof;
        uint256[] memory instances;
        (proof, instances) = utils.setParams(I_PROOF, I_INST); // set params

        bytes32 nullifier = keccak256(
            abi.encodePacked(address(verifier), proof, instances)
        );

        vm.expectEmit();
        emit InferenceVerified(verifier, proof, instances, address(this));
        bytes32 res = lb.verifyInference(verifier, proof, instances); // verify inference

        console.logBytes32(nullifier);
        assertTrue(nullifier == res);
        return nullifier;
    }

    function test_verifyModelNotRegistered() public {
        bytes memory proof;
        uint256[] memory instances;
        (proof, instances) = utils.setParams(I_PROOF, I_INST); // set params

        vm.expectRevert(abi.encodeWithSelector(ModelNotRegistered.selector));
        lb.verifyInference(verifier, proof, instances); // verify inference
    }

    function test_inferenceAlreadyVerified() public {
        test_verifyInference();

        bytes memory proof;
        uint256[] memory instances;
        (proof, instances) = utils.setParams(I_PROOF, I_INST); // set params

        vm.expectRevert(
            abi.encodeWithSelector(InferenceAlreadyVerified.selector)
        );
        lb.verifyInference(verifier, proof, instances); // verify inference
    }

    function test_invalidProof() public {
        this.test_registerModel();

        bytes memory proof;
        uint256[] memory instances;
        (proof, instances) = utils.setParams("0x", I_INST); // set params

        vm.expectRevert();
        lb.verifyInference(verifier, proof, instances); // verify inference

        string[] memory str_instances;
        (proof, instances) = utils.setParams(I_PROOF, str_instances);

        vm.expectRevert();
        lb.verifyInference(verifier, proof, instances); // verify inference
    }

    /* Test runFairness */
    function test_runFairness() public returns (bytes32) {
        bytes32 nullifier = this.test_verifyInference();
        uint256[] memory metrics = new uint256[](3);
        metrics[0] = uint256(1);
        metrics[1] = uint256(1);
        metrics[2] = uint256(1);
        vm.expectEmit();
        emit MetricsRun(verifier, metrics, nullifier);
        lb.runFairness(nullifier);

        return nullifier;
    }

    function test_alreadyChecked() public {
        bytes32 nullifier = this.test_runFairness();
        vm.expectRevert(
            abi.encodeWithSelector(InferenceAlreadyChecked.selector)
        );
        lb.runFairness(nullifier);
    }

    function test_isNotProver() public {
        bytes32 nullifier = this.test_verifyInference();
        vm.startPrank(makeAddr("random"));
        vm.expectRevert(abi.encodeWithSelector(NotProver.selector));
        lb.runFairness(nullifier);
        vm.stopPrank();
    }

    function test_inferenceExists() public {
        bytes memory proof;
        uint256[] memory instances;
        (proof, instances) = utils.setParams(I_PROOF, I_INST); // set params

        bytes32 nullifier = keccak256(
            abi.encodePacked(makeAddr("random"), proof, instances)
        );
        vm.expectRevert(abi.encodeWithSelector(InferenceNotExists.selector));
        lb.runFairness(nullifier);
    }
}
