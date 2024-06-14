// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IVerifier} from "../src/IVerifier.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Leaderboard} from "../src/Leaderboard.sol";
import {Halo2Verifier as VerifierCreditBias} from "../src/credit-bias/VerifierCreditBias.sol";
import {Halo2Verifier as VerifierCreditUnbias} from "../src/credit-unbias/VerifierCreditUnbias.sol";
import {Deploy} from "./Deploy.s.sol";
import {Utils} from "../utils/utils.sol";

contract LeaderboardScript is Script {
    HelperConfig helperConfig;
    Leaderboard leaderboard;
    VerifierCreditBias vfCBias;
    VerifierCreditUnbias vfCUnbias;
    Deploy deploy;
    Utils utils;

    string constant I_PROOF =
        "0x08ebd9ad34cf73bdf44f09f6c4a9ac54b959e0fc4b1243c801242e9ef678d2c818b635cc78b94d9df4d895d496970b796f08cfec1351d5050acfa3483e6e98ac21f5a82e434c9a07a624bf969168cf941973458b8b96c985d44c56ab2e79f87c253cfab85257b7977b528da3e549255102e32a0688e0b7828234beb33cf53d830ecab0e385590f9072c7f9b239216d77623c529c4f9c1ef0f76abb0b685ca7bf11f1305d4a3d57df604c6584e2da2094780dadc78806a978856eef46499f48d82bf01cc7e97f6502d867ea15e3883e75a9d2a21e85bc01f6265e5bb007e3c052068972d7837c8417bdac51d3a4a157ce2e23304f4f7098823b69273f8f68b0b32b8a90a53f94b5046483ef61a436c398cbeab1c676776285fd704e2e305368af10a70eca8c3c4075aaa029294228fd61b12a4bf7daf63b8ff4fb2cbae09e5a0c1ea9af642ed856f1505aa62f25f2799bf01322f5e66697c903c696d3a76875f62ca0a707417f641dd9f184a960b85e143eab2523d3831a694ab54c63219cbf462cf42b37f84b65f1dd73527ad8fff609ca519e943a5b0fc3db8e015c49181f2e2a0e24da14e6bc752aa0b8854f52c809da99fa128727b02cb5d2c300cf9f23660c58b1c843c151f1d98b8a00f06eda00b3a7e4f981159b2929dd43cda63c678c0c4d0fa58498c1583ad9a7d37e46c57f775c4b1eeb9161606044ca54303ab33130629588a4bbd24f0912aac3440501426d69c5a9dfe0787a7562dc7cf76b039a2907bdc1788c9f29539bd3cc0a591ded7d34659295e7548bb72e4b79870563272559c2e7a087e92d436c4b404f88b92d5a68d14e280b13bb0971b72c18ab8648188616c4b267c387e956675366d9cb445ea87e1c53625acb140531fa1ac14ef105d10ebbdbcb3aaeb49fb8d3345c7d7cd8ea2f8d2af72e1dff61ffb04d5391162d98be0cac28c199999fa20f48c3bc928d6b0d41c1ea35b6ed167f19834f262917fd82b7116a825aee3e06b413f423b703df3e06b5ee140b0ab557bd56aa6a550a9561e7b22acec0dea60130573bf9761e0d22920527fe2bfa87c6a651929b0f119252703c56d3ea4aea351c0e385494b4f86cb59f21d68b74819c85c56a64872b813f0fb19938a1b2a1a7a5af4632aa8faee1f77d53282c9a895cc6cceaf28e00577c5dc7510b687fd03b40c8718ca1b8a1330daa170d56349c5a79de6d10f90593096b71407e34ff579ee7b86792ea873f58f24933247328a34c3e0d1f911829f52522259eb6f9aca3127d424ecbf7bf124e266c449f6d54cfa88896d451020d7123451c83bbf52bc8a406cee4ad86c0d239f9d405ef1fe448be1f8a754f42304a8bd6958a8332dc7a025f630d1dbc293c129b939a719f7f623e9b8fd04943301f1ebd4f7d1d1a3c3ea96ac6946f39bcee406f00e22cd595bc35212924c4cc02ca0d0497ec30da9f01c7d7f2c8e4d740f87065ad82c97228d7ab4c5c473ea1000ea68f8541d1050e76237c903931459c52804d2320c7ffe4b694f6c1bab3c00006ec4cf0da05e19177ddb0d7002c89ed13c96e94de87d921d825642d73ce7e0c3ea87afbd59dd692bb535d0c69deb64a7488b2477464cb9f7c8087c78386e200577c5dc7510b687fd03b40c8718ca1b8a1330daa170d56349c5a79de6d10f90593096b71407e34ff579ee7b86792ea873f58f24933247328a34c3e0d1f9118089a279cff47cc35669c79644a28ddb1805ba457a8cdf1eb64937b37466c2c5f22fac3a9ff1e9127501e8536867924d29186266899130cc4579ef60cdefbc1842b3978f200e5edb5a9f79b340a5c48cae0a41beeaf2fe81b1939379a92b2f95a0c1561f95ceab9ae2c925fdacc5613cd6f1a8c8c868485eec4ea282fb18c7d8b02d2484f53253e31872ffde4fa953bb266bfb693f0f4e0201cb928bb4b612959034b7dd3861cf8e4d6f6aeb834b47e224aa9dc0cadc317ab77e3b959d6becf9e0d2211bd3cb2d09353c88afc8196a3fc0e09196e7253ab22f4fffa2decc70d8927234ee1b9a5ea6099728dbe3bb473e56b128b94d8c077694ae51b8fe03f30d20c73879385d51b3d2c9b34dba641167eee4d4599642328744c0c74a97b5978a31619d0e71cdeef56a2487252d41044de9411974fed4b5eada32c86240db6bb770c9db93636d0dce02c75006bb5dfedc69f3dfde81097c013c6f3817a3fd8dbeb09cfb83dae67d378813d83c8fa49961ff29c952b0031aebd6f80469bceca35ab09c6a1e908d7a09568615916428bef4c16eac1feea8cce5704756aba5701487a1765d5a004a7009e6f377e3b90214dc0e9c32452496e2c36baaa1f60c2384eba1d88084549c4db18b8c7b59b522708a8c14c9ea365e09a252732c2db7e386b3d057116ee60654d3c9e670500913f4acd06fd269258bf6f788389967582ca8902095a7d306545b24d5261765a11a923db410160510611b5c3be72390093c2a74b12b995de3f7d96ecf61cce14c296b3f9e042d2fb7c31319fc0a1b1ed6cac12a91a28f120f6b3f215428904cefa56745e223b9d6e9d7463509be7220b215bbb3d1374caa89272143657866ac5d04a3fe4af84eea05e0dc0f0620ee3ab373bc291044e80aadb0e530fbc01ef4ebed0e895fd35a15e61f738c78596edce4c8de2d309b81991316452a7c0d122df9891704443b684a2c888eb9d804524f4ba70086f27dd47298fcd5918ad22be18b6283f8328afc0cb0809db64200f10be1730fb771c2f8723abf6616fa4713d8e55446874922b3e7c2947c1c52c9350465d6bdd520863b2a421b630d06b45a0ea0d1825e41c932469be4abd9b5b33a4587c9fc60b267065775b8349c24926b6eaa2d0829c19fe47d9de947c0161c9d739788b4cd7272e8408b91412c37f41fa3f5b49c01e7d7eeb0610fd1252028fe8192d2baa911e31d30ac3fae6e0ecae1e6d6c6e5f2315793f38d396a19d62f9b2935d0e5a9405a92dfbd55f7a2f2d8caeac9897894dcd7c6f5a85d909738d465d298ebfb4f42c3def912fb8d7abe9e0b40cf016261991c82936764423d2a285612790ebd899277d95418e13431aba91955b11d57264a4deae97342a3b775bced6e608b272692a6fd8df396ce35b9b455d370d0e1a2a426c14b33beb0cee564ec8bdf4e9499e256829a284b82476ab3804a9847268c577d66cfb3cb689d2292cd52058133ed80da53569d77b5a288f4debd11307baef285d25a50550dd51dae33dab6c7d30982e279504048bb57f0dbf4b742c65cd70b730a5051af1b5d5839978393bf336f621aa34b2d8d87e15b588e59be404c2dfcf21b9ddd92c1984fbe9d7cd65fac1262d64331df0bea897deed1469c71e7b65768dee52c238532a5e8018abf3c9125f19ddb735080120eb4a074e34353ff2e26ade673e8f9ce70e8bba6543ab961ab000497f3ee97ee59f91348fff52c1d0459863da9c46418bf17187abcb2bd77aa106ebaea91c1dd80b9b088ea2f9dd31333d112c0cf3db8f6087f17392c63761b12f05ec363dc34482bab1e5d9ba3610ca4b98497387cd8487bb33dced65644e7c2ab2bf3b191e9cfd83870e58e6dc464377b004828c0404702798d64cc1eea3f70d55f4fd6b0968240a758713c3a6789dbc85107b73d987b3d0d0613d39624f6128c081961484439b56db2be379617bd4af17e4ff13bca7290bf9b613f66b79a20e9f6af210fceea371053515306058417eae68ce91843dec2bf679818c04686f0c7a9a576f04910ff917fd6a1991acdf90eed7091055f2345743c653e1ffa8392f7699c1c30b22b620370c4aa9cde09eb06902874c5597f01b58e605f48340751e66a9371a4c57cba71a82489d80fbb8850aa214910ff115f4154f3908f02f9119efbba93d0c861114a77dd42cebf54a5a4ae5d88a060fbc222ed4fbade7be51027b00abcbaa8136921d6adae669adb49e76273478fc5702b2849106d5c9f52b08ebe6dbdf9ba37280be1785a7922ac5ecf98145592ac3a251f6e936d3a885421eb213211cf599e5fb8776059917e79be5d3deb5409f0cac3a301bf37afbf755259f9d454a6a18acfafdc1862e1ca26b472929559fd35ad2e70793e9d5925c4f00000000000000000000000000000000000000000000000000000000000000001367fa374eadfd12e23f8fa594f1055e925ae5723800e981e6c498d27df0bb331c516b2b0ab49d8aacfcc3054238459ad03d93231db539a000b7310aaccc3b591b2d6cb7f9a27bc3c7651f239d763270e8278f67787c56b6e5882e514e5e2a6c130821e7317c8ab11a31b9f75cd0f864979e065bde45f48b00bf18057f8e8ee0000000000000000000000000000000000000000000000000000000000000000017f9ead9404182cab7613501cde43c883722a975a890dea61617dce2b6e7680a15327c1bd5805dace3b4d37479405bc4c25ba72bf8fe8fa7f63fa4119e8ab01013bdc680e53bb583a72b05d4c44c3ade3472edfb596c163b7f32ba005658e1e2218b44bab37843731d36545bebbaa1b6cad2a72eabda9189e0d56cd26ef3b868191db95d288a12a492b92acdc542fb71530c11a0efb31584105a9b7feda6572a2098dc4827a826e5c145a49b09969fb8c696c3352de4ab304fc4bd0a2c87ea620e6c70513fe67046bc36fb6089ebf4bdc9a5a3581d051ddc29f0e79b49ea8f3c25ea1f2851313affc010c4a0f9c66d1e5700d1d4210d750ceec1190432516ffd0000000000000000000000000000000000000000000000000000000000000000230181edf92bafb8452d488b3d0ed4ae4e6e2b59e1c3a41a6557c72f8aa1febb2ffe2808f85823db267c0654fa35d438f7fe56738daad976520bb37fe75f65f314e7a52cdeba30e97135930b548ba3709a4aff5480186a9fca838f044d3d9404253dd3af9d34c633bea59a37131275d298488332eb0717ae207d18ee78cd9bd31d1e05450448eef6e81a4dec981915dce05f80056494913565fd4dd01a65c43a10006bd1eeb6411c77020e45cc01c57d0653d46a829bf1fe89a9f103716de7a10a3df73f67516ea63ccf953d45f8180d875bc098a8942fd26956fde54f5c30b51d3f6145248259e42da64193d77baa39d55157efeae1681d8bbc7cbb48edd7b829938d7707551f136454f1579c44c35b45426bc5488f733b4e19fcb2fecf07000fbc9f30ad4b043afd7d8404c11c27656c286e9adb15538abc98e6b0669da4de10dc2fecb5e053f6f1f3b2629902e8fcb2b9de441d940ee258b45917db15f3d9161eceaa340336365f2f91f98cf33750c97e3fccc19d523f74308e3236e1cd8708912d3b85c0cb25569cb534f979a41df60e167b080591c3333fbd5066958a20005a71d4f4773058440557d90a2c416f2e0e5215827bf29b2dc59e7b4082b8262f8192bc3e89dda592ecfcdb2339b90aec762d397a80148191caf0753bfadd1018cf2400bee017a000cc7818444dbe196de8ff34ec5a15c861083f4cf8ea6440298123c07ad6dfa41f2024e1231daebca1109ed33b05827f1af73e18379a26892aec00f57017d2719af0741cd125058f9142ccda7e54fa63a475bd0c1dfd1233100b1b3294c9c80adea8d1b2acb63f499c755e6f53d1aac85b4e1236585dae640dc55c806267319e158eb04e540ebb9d7f3a07da46e97e8767550cc52d09211f0bc8bb13f63ff0288161ce8def0258dd1cc06be5e845ae219d98dc4a15dc0a202d45d927806575b79c803676194bc5dbe0b1ef9ffad21ed506b2a9133a4a35c6299c2ff097f6d13056640b8ef2af278387e7dd8f5ba1ad95b95151a323f2d8d020511849ff99ef1d9a7e86d5fe993eab40936ca0f1a8d23ac7637e71d35749631b67784bfeeb682f09044cff38869c18cee32750fac0cf72f4b790a7d852cc242eb9ab9a7eb7441e994354278ddd6cb49a8e56aabdbde07c0809fd4d5b1f1c051b5e0df02946cd260afa658d179e249ced6bb08bbc727e724f2097e5cb848f3e12a982384eb59dba8f5f5a4d1ea292932a0bdab9bdbd6322c415965f55e9a6c91b6cb2d07182eb54525ba75d344dca153188a5124801d6200f50696e6caef037146afc5feb158005e2b5a1ae127e9df904804a0c639005611bbe4f09e4b75ca12b38de124150fb44be125e3c00e4072b06779378131a577ac3ada3906395580826b138ffd0966abce9b211a08fee0a971616e32335b934bed32e46339a9b5d31223756bacf417e0bc2d15f071955fd0056390fbf215cb3840f0ed90135216ddf2f8c299168a3e01397ef99ce0fef687c5d0626a448df2caad0f54a72e89f30b90f572f8be17d1227bdb511533302951ecefeb7f5151af624ab22a2dd9b85f90e20b055e6122644327553d822fc7294d4824d8962185956510652b40b2ec1363f0eca5e80dc0012c5c86917f6f824960611f346e986102d2f99143504577d8c450d445d12c8e0188003806b6aa6365df8c96a93d9c199e0b5485fe5552740dcb8173fbe9e50dc4ccc027c3aac9c9c6f2c4c35a840801606730c71a8bb33bd7c3e122f764b7d34ca70089642eea5e6716db673f4659dc1d95ce700519596bfd6f0096fc50cd4b8d1bdb862acd3e03f60e88e915a0b00d60cfaaa0af4e16287477f0de62c3603c3b07151eebccedf5d1c15cdc00aa7f4dd60e164e132c6006e9fda2d9c06a9320df379b4a2ac8d4aaedebbcfa7f3f66795efa962f5d24e3661db7a22a32cfbcc609ab9441b69f19ab39f9e70f5d8543fe7c7a404fd48d6c00dc199056129de99e6c4b6090d11ba99742a939ad65e0c3f18f0c7fac13e476682b2e717d94ceb694462f5aba485414bfe8a4c13cee8d238e1ddbbe12278e118fa29d3049dbfce9e322a623040d3113e11f0951627c9a71f9455099df3a92ca181e49102af0d4eec6df24c7a5e146f10d0b7695522b171ac0bcc38f6aa9c5daed965362247e4adca9a99eafcb7a7cce4234c5d0d568fe1f84cd7b2738fe138b4bfa91305278ca644cc6fac9733543519c81d527d8d80ab89238d4520dacf8eb4e4075020b055e6122644327553d822fc7294d4824d8962185956510652b40b2ec1363f270809d541ab932f7b01b2d6913ebb8fb776765e681f753a777fc439aad13e582ae3a2f6bc075d307bd93562d0efbaafe580c97c3ed6844268d135515eb7e98e0ed9fe225682b809905830fb418eb136dfcea9651afb85ed9ec2c15199b9590d09795c4098b553fe25acbe6014b4cc81fcd014c1a25b2b2d2efdea3bd544a492";
    string[] public I_INST;

    function setUp() public {
        utils = new Utils();
        I_INST = [
            "0x0000000000000000000000000000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000000000000000000000000eeb",
            "0x0000000000000000000000000000000000000000000000000000000000000115"
        ];
    }

    function run() public {
        helperConfig = new HelperConfig();
        (, uint256 deployerKey2) = helperConfig.activeNetworkConfig();
        deploy = new Deploy();
        (leaderboard, vfCBias, vfCUnbias) = deploy.run();

        vm.startBroadcast(deployerKey2);

        leaderboard.registerModel(IVerifier(address(vfCBias)));

        bytes memory proof;
        uint256[] memory instances;
        (proof, instances) = utils.setParams(I_PROOF, I_INST);

        bytes32 nullifier = leaderboard.verifyInference(
            IVerifier(address(vfCBias)),
            proof,
            instances
        );

        leaderboard.runFairness(nullifier);

        vm.stopBroadcast();
    }
}
