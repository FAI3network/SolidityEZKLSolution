`ezkl-demo/`: proving, verification and generation of verifier contract with ezkl library.

`src/`: Verifier & Dashboard contracts.

`test/`: verifier contract tests.

to compile contracts: `forge build`

to run tests: `forge test -vvv --ffi`

1. usuario sube modelo, settings
2. compilar, pk, vk
3. pk + circuito + data => prueba
4. vk => verifier
