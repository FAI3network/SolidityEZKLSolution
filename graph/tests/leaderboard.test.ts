import { Address, BigInt, Bytes, ethereum, log } from "@graphprotocol/graph-ts";
import {
  afterAll,
  assert,
  beforeAll,
  clearStore,
  describe,
  test,
} from "matchstick-as";
import {
  createInferenceVerifiedEvent,
  createMetricsRunEvent,
  createModelRegisteredEvent,
} from "./leaderboard-utils";
import {
  handleInferenceVerified,
  handleMetricsRun,
  handleModelRegistered,
} from "../src/leaderboard";
import {
  InferenceVerified,
  MetricsRun,
  ModelDeleted,
  ModelRegistered,
} from "../generated/schema";

test(
  "Model Registered Event should be handled correctly",
  () => {
    // create a new model registered event
    let verifier = Address.fromString(
      "0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7"
    );
    let owner = Address.fromString(
      "0x99995A3A3b2A69De6Dbf7f01ED13B2108B2c43e7"
    );
    let newModelRegisteredEvent = createModelRegisteredEvent(
      verifier,
      owner,
      "hola"
    );
    handleModelRegistered(newModelRegisteredEvent);
    assert.bytesEquals(
      newModelRegisteredEvent.params.verifier,
      verifier,
      "Verifier should be the same"
    );
    assert.bytesEquals(
      newModelRegisteredEvent.params.owner,
      owner,
      "Owner should be the same"
    );
  },
  false
);

describe("Inference Verified Event", () => {
  afterAll(() => {
    clearStore();
  });

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("InferenceVerified created and stored", () => {
    let proof = Bytes.fromI32(1234567890);
    let instances = [BigInt.fromI32(234)];
    let prover = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    );
    let verifier = Address.fromString(
      "0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7"
    );
    let newInferenceVerifiedEvent = createInferenceVerifiedEvent(
      verifier,
      proof,
      instances,
      prover
    );
    handleInferenceVerified(newInferenceVerifiedEvent);

    assert.entityCount("InferenceVerified", 1);
    assert.bytesEquals(
      newInferenceVerifiedEvent.params.verifier,
      verifier,
      "Verifier should be the same"
    );
    assert.bytesEquals(
      newInferenceVerifiedEvent.params.proof,
      proof,
      "Proof should be the same"
    );
    assert.bytesEquals(
      newInferenceVerifiedEvent.params.prover,
      prover,
      "Prover should be the same"
    );
    let array = newInferenceVerifiedEvent.params.instances;
    // check if the array is the same
    for (let i = 0; i < array.length; i++) {
      assert.bigIntEquals(
        array[i],
        instances[i],
        "Instances should be the same"
      );
    }
  });
});

describe("Metrics Run Event", () => {
  beforeAll(() => {
    // before all, create a new model registered event
    let verifier = Address.fromString(
      "0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7"
    );
    let owner = Address.fromString(
      "0x99995A3A3b2A69De6Dbf7f01ED13B2108B2c43e7"
    );
    let modelURI = "hola";
    let newModelRegisteredEvent = createModelRegisteredEvent(
      verifier,
      owner,
      modelURI
    );
    handleModelRegistered(newModelRegisteredEvent);
  });
  afterAll(() => {
    clearStore();
  });

  test("MetricsRun created and stored", () => {
    let metrics = [
      BigInt.fromString("-111111111111111111"),
      BigInt.fromString("833333333333333333"),
      BigInt.fromString("-333333333333333333"),
      BigInt.fromString("-166666666666666667"),
    ];
    let verifier = Address.fromString(
      "0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7"
    );
    let newMetricsRunEvent = createMetricsRunEvent(verifier, metrics);
    handleMetricsRun(newMetricsRunEvent);

    assert.entityCount("MetricsRun", 1);
    assert.bytesEquals(
      newMetricsRunEvent.params.verifier,
      verifier,
      "Verifier should be the same"
    );

    let array = newMetricsRunEvent.params.metrics;
    for (let i = 0; i < array.length; i++) {
      assert.bigIntEquals(array[i], metrics[i], "Instances should be the same");
    }
    let modelR = ModelRegistered.load(verifier.toHexString());
    if (modelR) {
      for (let i = 0; i < array.length; i++) {
        // check if the avgMetrics is the same as the metrics. avgMetrics is BigDecimal and metrics is BigInt

        log.info("metrics: {}", [modelR!.metrics![i].toString()]);
      }
    } else {
      log.error("ModelRegistered not found", []);
    }
    log.info("------------------------------", []);
    metrics = [
      BigInt.fromString("-111111111111111111"),
      BigInt.fromString("750000000000000000"),
      BigInt.fromString("-333333333333333333"),
      BigInt.fromString("-500000000000000000"),
    ];
    verifier = Address.fromString("0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7");
    newMetricsRunEvent = createMetricsRunEvent(verifier, metrics);
    handleMetricsRun(newMetricsRunEvent);

    modelR = ModelRegistered.load(verifier.toHexString());
    if (modelR) {
      for (let i = 0; i < array.length; i++) {
        log.info("metrics: {}", [modelR!.metrics![i].toString()]);
      }
    } else {
      log.error("ModelRegistered not found", []);
    }
  });
});
