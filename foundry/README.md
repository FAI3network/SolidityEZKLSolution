`ezkl-demo/`: proving, verification and generation of verifier contract with ezkl library.

`src/`: Verifier & Dashboard contracts.

`test/`: verifier contract tests.

to compile contracts: `forge build`

to run tests: `forge test`

1. usuario sube modelo, settings
2. compilar, pk, vk
3. pk + circuito + data => prueba
4. vk => verifier

Run scripts:

1. start anvil: `anvil`
2. deploy leaderboard: `forge script "script/Deploy.s.sol:DeployLeaderboard" --fork-url "http://127.0.0.1:8545" --broadcast`
3. interact with leaderboard: `forge script "script/Interactions.s.sol" --fork-url "http://127.0.0.1:8545" --broadcast`

deploy & verify contract:

```
forge script "script/Deploy.s.sol:DeployLeaderboard" --broadcast --rpc-url $SEPOLIA_RPC --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/11155111/etherscan' --etherscan-api-key $ETHERSCAN_API_KEY
```

verify an already deployed contract:

```
forge verify-contract 0x8f519D61802567794f9a2109e1A8AE2eF67D4369 "src/Leaderboard.sol:Leaderboard" --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/11155111/etherscan' --etherscan-api-key $ETHERSCAN_API_KEY --num-of-optimizations 200 --compiler-version 0.8.20
```
