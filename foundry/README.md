`ezkl-demo/`: proving, verification and generation of verifier contract with ezkl library.

`src/`: Verifier & Dashboard contracts.

`test/`: verifier contract tests.

to compile contracts: `forge build`

to run tests: `forge test -vvv --ffi`

1. usuario sube modelo, settings
2. compilar, pk, vk
3. pk + circuito + data => prueba
4. vk => verifier

Run scripts:

1. start anvil: `anvil`
2. deploy leaderboard: `forge script "script/Deploy.s.sol:DeployLeaderboard" --fork-url "http://127.0.0.1:8545" --broadcast`
3. interact with leaderboard: `forge script "script/Interactions.s.sol" --fork-url "http://127.0.0.1:8545" --broadcast`
