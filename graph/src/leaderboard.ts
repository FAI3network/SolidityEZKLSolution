import { Address, BigDecimal, BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  InferenceVerified as InferenceVerifiedEvent,
  MetricsRun as MetricsRunEvent,
  ModelDeleted as ModelDeletedEvent,
  ModelRegistered as ModelRegisteredEvent,
} from "../generated/Leaderboard/Leaderboard";
import {
  InferenceVerified,
  MetricsRun,
  ModelDeleted,
  ModelRegistered,
} from "../generated/schema";

export function handleModelRegistered(event: ModelRegisteredEvent): void {
  let modelRegistered = ModelRegistered.load(
    getModelIdFromEventParams(event.params.verifier)
  );
  if (!modelRegistered) {
    modelRegistered = new ModelRegistered(
      getModelIdFromEventParams(event.params.verifier)
    );
  }
  modelRegistered.verifier = event.params.verifier;
  modelRegistered.owner = event.params.owner;
  modelRegistered.avgMetrics = new Array<BigDecimal>();
  modelRegistered.numberOfInferences = 0;
  modelRegistered.save();
}

export function handleModelDeleted(event: ModelDeletedEvent): void {
  let modelDeleted = ModelDeleted.load(
    getModelIdFromEventParams(event.params.verifier)
  );
  let modelRegistered = ModelRegistered.load(
    getModelIdFromEventParams(event.params.verifier)
  );
  if (!modelDeleted) {
    modelDeleted = new ModelDeleted(
      getModelIdFromEventParams(event.params.verifier)
    );
  }

  modelDeleted.verifier = event.params.verifier;
  modelDeleted.owner = event.params.owner;

  modelRegistered!.owner = Address.fromString(
    "0x000000000000000000000000000000000000dEaD"
  ); // dead address to recognize model deleted

  modelDeleted.save();
  modelRegistered!.save();
}

export function handleInferenceVerified(event: InferenceVerifiedEvent): void {
  let inferenceVerified = InferenceVerified.load(
    getInferenceIdFromEventParams(event.params.verifier, event.params.proof)
  );
  if (!inferenceVerified) {
    inferenceVerified = new InferenceVerified(
      getInferenceIdFromEventParams(event.params.verifier, event.params.proof)
    );
  }
  inferenceVerified.proof = event.params.proof;
  inferenceVerified.instances = event.params.instances;
  inferenceVerified.prover = event.params.prover;
  inferenceVerified.verifier = event.params.verifier;

  inferenceVerified.save();
}

export function handleMetricsRun(event: MetricsRunEvent): void {
  let metricsRun = MetricsRun.load(
    getMetricsIdFromEventParams(event.params.verifier, event.params.nullifier)
  );
  let modelRegistered = ModelRegistered.load(
    getModelIdFromEventParams(event.params.verifier)
  );
  if (!metricsRun) {
    metricsRun = new MetricsRun(
      getMetricsIdFromEventParams(event.params.verifier, event.params.nullifier)
    );
  }
  metricsRun.nullifier = event.params.nullifier;
  metricsRun.metrics = event.params.metrics;
  metricsRun.verifier = event.params.verifier;

  if (modelRegistered!.avgMetrics!.length == 0) {
    // initialize avgMetrics
    for (let i = 0; i < event.params.metrics.length; i++) {
      modelRegistered!.avgMetrics!.push(
        BigDecimal.fromString(event.params.metrics[i].toString())
      );
    }
  } else {
    // update avgMetrics : newAvg = (currentAvg * numInferences + newValue) / (numInferences + 1)
    let numInferences = BigDecimal.fromString(
      modelRegistered!.numberOfInferences.toString()
    );
    for (let i = 0; i < event.params.metrics.length; i++) {
      let currentAvg = modelRegistered!.avgMetrics![i];
      let newValue = event.params.metrics[i].toBigDecimal();

      let newAvg = currentAvg
        .times(numInferences)
        .plus(newValue)
        .div(numInferences.plus(BigDecimal.fromString("1")));

      modelRegistered!.avgMetrics![i] = newAvg;
    }
  }
  modelRegistered!.numberOfInferences++;

  metricsRun.save();
  modelRegistered!.save();
}

function getModelIdFromEventParams(verifier: Bytes): string {
  return verifier.toHexString();
}

function getInferenceIdFromEventParams(verifier: Bytes, proof: Bytes): string {
  return verifier.toHexString() + proof.toHexString();
}

function getMetricsIdFromEventParams(
  verifier: Bytes,
  nullifier: Bytes
): string {
  return verifier.toHexString() + nullifier.toHexString();
}
