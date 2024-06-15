import { Address, BigInt, Bytes } from "@graphprotocol/graph-ts";
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
    getModelIdFromEventParams(event.params.modelId, event.params.verifier)
  );
  if (!modelRegistered) {
    modelRegistered = new ModelRegistered(
      getModelIdFromEventParams(event.params.modelId, event.params.verifier)
    );
  }
  modelRegistered.modelId = event.params.modelId;
  modelRegistered.verifier = event.params.verifier;
  modelRegistered.owner = event.params.owner;

  modelRegistered.save();
}

export function handleModelDeleted(event: ModelDeletedEvent): void {
  let modelDeleted = ModelDeleted.load(
    getModelIdFromEventParams(event.params.modelId, event.params.verifier)
  );
  let modelRegistered = ModelRegistered.load(
    getModelIdFromEventParams(event.params.modelId, event.params.verifier)
  );
  if (!modelDeleted) {
    modelDeleted = new ModelDeleted(
      getModelIdFromEventParams(event.params.modelId, event.params.verifier)
    );
  }

  modelDeleted.modelId = event.params.modelId;
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
    getInferenceIdFromEventParams(event.params.modelId, event.params.proof)
  );
  if (!inferenceVerified) {
    inferenceVerified = new InferenceVerified(
      getInferenceIdFromEventParams(event.params.modelId, event.params.proof)
    );
  }
  inferenceVerified.modelId = event.params.modelId;
  inferenceVerified.proof = event.params.proof;
  inferenceVerified.instances = event.params.instances;
  inferenceVerified.prover = event.params.prover;

  inferenceVerified.save();
}

export function handleMetricsRun(event: MetricsRunEvent): void {
  let metricsRun = MetricsRun.load(
    getMetricsIdFromEventParams(event.params.modelId, event.params.nullifier)
  );
  if (!metricsRun) {
    metricsRun = new MetricsRun(
      getMetricsIdFromEventParams(event.params.modelId, event.params.nullifier)
    );
  }
  metricsRun.modelId = event.params.modelId;
  metricsRun.nullifier = event.params.nullifier;
  metricsRun.metrics = event.params.metrics;

  metricsRun.save();
}

function getModelIdFromEventParams(modelId: BigInt, verifier: Address): string {
  return modelId.toHexString() + verifier.toHexString();
}

function getInferenceIdFromEventParams(modelId: BigInt, proof: Bytes): string {
  return modelId.toHexString() + proof.toHexString();
}

function getMetricsIdFromEventParams(
  modelId: BigInt,
  nullifier: Bytes
): string {
  return modelId.toHexString() + nullifier.toHexString();
}
