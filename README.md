# FAI3

## 1) Model submission + ezkl:

#### Make sure you have the following dependencies installed:

- python 3.11
- numpy
- tqdm
- aif360
- sklearn
- matplotlib
- xgboost
- ezkl
- torch
- hummingbird.ml
- pandas

Go to `notebooks/`:

```
cd notebooks
```

### Run `credit_example.ipynb`

This script trains 2 xgboost models with different credit score datasets from aif360, the first dataset is biased and the second unbiased.

All files get stored at `ezkl/credit-bias` and `ezkl/credit-unbias`.

_Note: If you create your own model, you should change the paths as needed._

For each model:

1. Converts XGBoost model to PyTorch.
2. Exports the Pytorch model to ONNX: `network.onnx`.
3. Gets inputs and outputs datasets for testing: `x_test.csv` and `y_test.csv`.
4. Converts the 20 first inputs into .json format: `inputs/input[i].json`
5. ezkl cycle ([Reference](https://docs.ezkl.xyz/#the-life-cycle-of-a-proof)):

   1. generate settings: `settings.json`
   2. calibrate settings: `calibration.json`
   3. compile circuit:

      compile(onnx model, settings) -> `network.ezkl` (circuit)

   4. get srs file: `kzg.srs`
   5. generate witness for each input file: `witnesses/witness[i].json`
   6. setup

      setup(circuit, srs) -> `pk.key` (to generate proofs) and `vk.key` (to verify proofs)

   7. generate proofs:

      prove(circuit,witness[i], pk) -> `proofs/proof[i].json`

   8. verify proofs to check if the proofs are valid:

      verify(proof[i], vk) -> boolean

6. Gathers all proofs, instances, and targets (expected outputs from test dataset) and pretty outputs and stores them in `output.json`.

   `hex_proofs` and `instances` arrays are used next for making calls to the Leaderboard contract. It's all the info a user needs to verify inferences.

7. Generate the `Verifier` contract. This contract will be used to verify all the proofs on-chain.

   _Note: I've done this step with ezkl CLI because using python lib was not working_.

   [Install ezkl CLI](https://docs.ezkl.xyz/installing/#installing): [Release binary](https://github.com/zkonduit/ezkl/releases).

   Once installed, run from your terminal:

   ```
   ezkl create-evm-verifier --srs-path="../ezkl/credit-bias/kzg.srs" --vk-path "../ezkl/credit-bias/vk.key" --sol-code-path "../foundry/src/credit-bias/VerifierCreditBias.sol" --settings-path="../ezkl/credit-bias/settings.json" --abi-path="../ezkl/credit-bias/verifier_abi.json"
   ```

   This script generates a `Halo2Verifier.` contract at `/foundry/src/credit-bias/VerifierCreditBias.sol` and its abi at `/ezkl/credit-bias/verifier_abi.json`.

Great! The next step is to deploy the verifier contract with foundry and then verify the proofs of inference and run the metrics.

### Environment Variables

---

To continue with the next steps, you will need to add the following environment variables to your `.env` file:

`MAINNET_RPC` (optional)

`SEPOLIA_RPC`

`DEPLOYER_PRIVATE_KEY`

`DEPLOYER_PRIVATE_KEY_2`

`ETHERSCAN_API_KEY` (optional)

get your rpcs: https://dashboard.alchemy.com/apps

## 2) Deploy Leaderboard and interact locally

#### Make sure you have the following dependencies installed:

- [foundry](https://book.getfoundry.sh/getting-started/installation)

The `Leaderboard.sol` is already deployed on sepolia: [0x51395Fd32809D0280d1422344369518AB876b292](https://sepolia.etherscan.io/address/0x51395Fd32809D0280d1422344369518AB876b292)

_This step shows how to deploy Leaderboard.sol on any EVM network (replacing the `--fork-url` param). In this example is done locally._

First you need to start anvil:

```
anvil
```

Create a new terminal and change directory to `foundry/`:

```
cd foundry
```

Run to deploy `Leaderboard.sol`:

```
forge script "script/Deploy.s.sol:DeployLeaderboard" --fork-url "http://127.0.0.1:8545" --broadcast
```

Then to interact with the Leaderboard contract, you need to run the `Interactions.s.sol` script.

To do that, get the values generated on the 1st step stored at `ezkl/credit-bias/output.json` and replace the following variables of the script:

`I_PROOFS_BIAS` = `hex_proofs`

`I_INSTS_BIAS` = `instances`

`TARGETS` = `targets`

You also have create a model URI following this template and encoding it in base64:

```json
{
  "name": "Credit Scoring Xgboost Model",
  "description": "An Xgboost-based machine learning model for credit scoring applications.",
  "imageURL": "https://example.com/credit_scoring_xgboost.png",
  "framework": "Xgboost",
  "version": "1.0",
  "hyperparameters": {
    "max_depth": 5,
    "learning_rate": 0.05,
    "n_estimators": 200,
    "objective": "binary:logistic"
  },
  "trained_on": "https://archive.ics.uci.edu/dataset/144/statlog+german+credit+data",
  "deployed_with": "Kubernetes cluster",
  "created_by": "FinanceMLCo",
  "date_created": "2023-10-15"
}
```

[encode it to base64](https://www.base64encode.org/) and add prefix (`data:application/json;base64,`) to generate link:

```
data:application/json;base64,ewogICJuYW1lIjogIkNyZWRpdCBTY29yaW5nIFhnYm9vc3QgTW9kZWwiLAogICJkZXNjcmlwdGlvbiI6ICJBbiBYZ2Jvb3N0LWJhc2VkIG1hY2hpbmUgbGVhcm5pbmcgbW9kZWwgZm9yIGNyZWRpdCBzY29yaW5nIGFwcGxpY2F0aW9ucy4iLAogICJpbWFnZVVSTCI6ICJodHRwczovL2V4YW1wbGUuY29tL2NyZWRpdF9zY29yaW5nX3hnYm9vc3QucG5nIiwKICAiZnJhbWV3b3JrIjogIlhnYm9vc3QiLAogICJ2ZXJzaW9uIjogIjEuMCIsCiAgImh5cGVycGFyYW1ldGVycyI6IHsKICAgICJtYXhfZGVwdGgiOiA1LAogICAgImxlYXJuaW5nX3JhdGUiOiAwLjA1LAogICAgIm5fZXN0aW1hdG9ycyI6IDIwMCwKICAgICJvYmplY3RpdmUiOiAiYmluYXJ5OmxvZ2lzdGljIgogIH0sCiAgInRyYWluZWRfb24iOiAiaHR0cHM6Ly9hcmNoaXZlLmljcy51Y2kuZWR1L2RhdGFzZXQvMTQ0L3N0YXRsb2crZ2VybWFuK2NyZWRpdCtkYXRhIiwKICAiZGVwbG95ZWRfd2l0aCI6ICJLdWJlcm5ldGVzIGNsdXN0ZXIiLAogICJjcmVhdGVkX2J5IjogIkZpbmFuY2VNTENvIiwKICAiZGF0ZV9jcmVhdGVkIjogIjIwMjMtMTAtMTUiCn0=
```

Use that value for `MODEL_URI` variable.

Now, you are able to deploy the `VerifierCreditBias.sol` contract, register the verifier on Leaderboard, verify all the inference proofs and then run metrics of the model.

Run:

```
forge script "script/Interactions.s.sol" --fork-url "http://127.0.0.1:8545" --broadcast
```

You can see in your console the values of the calculated metrics.

Awesome!!

To interact with the Leaderboard contract, you need to run the `Interactions.s.sol` script.

Replace the variables values as defined in 2)1).

Also replace `lb_address` with the Leaderboard address:

```solidity
address lb_address = 0x51395Fd32809D0280d1422344369518AB876b292;
```

Load the environment variables:

```
source .env
```

Now, you are able to deploy the `VerifierCreditBias.sol` contract, register the verifier on Leaderboard, verify all the inference proofs and then run metrics of the model.

```
forge script "script/Interactions.s.sol" --rpc-url $SEPOLIA_RPC --broadcast
```
