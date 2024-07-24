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
import { log } from "matchstick-as";

export function handleInferenceVerified(event: InferenceVerifiedEvent): void {
  let inferenceVerified = InferenceVerified.load(
    getInferenceIdFromEventParams(event.params.verifier, event.params.proof)
  );
  if (!inferenceVerified) {
    inferenceVerified = new InferenceVerified(
      getInferenceIdFromEventParams(event.params.verifier, event.params.proof)
    );
  }
  let modelRegistered = ModelRegistered.load(
    getModelIdFromEventParams(event.params.verifier)
  );
  modelRegistered!.numberOfInferences++;
  inferenceVerified.proof = event.params.proof;
  inferenceVerified.instances = event.params.instances;
  inferenceVerified.prover = event.params.prover;
  inferenceVerified.verifier = event.params.verifier;
  inferenceVerified.instances = event.params.instances;
  inferenceVerified.save();
  modelRegistered!.save();
}

export function handleMetricsRun(event: MetricsRunEvent): void {
  let metricsRun = MetricsRun.load(
    getMetricsIdFromEventParams(event.params.verifier, event.transaction.hash)
  );
  let modelRegistered = ModelRegistered.load(
    getModelIdFromEventParams(event.params.verifier)
  );
  if (!metricsRun) {
    metricsRun = new MetricsRun(
      getMetricsIdFromEventParams(event.params.verifier, event.transaction.hash)
    );
  }
  metricsRun.metrics = event.params.metrics;
  metricsRun.verifier = event.params.verifier;
  metricsRun.blockNumber = event.block.number;
  metricsRun.blockTimestamp = event.block.timestamp;

  // log.info("metricsRun: {}", [metricsRun.id]);
  // log.info("modelRegistered: {}", [modelRegistered!.id]);
  // // log avgMetrics length
  // log.info("avgMetrics length: {}", [
  //   modelRegistered!.avgMetrics!.length.toString(),
  // ]);

  // divide each element of event.params.metrics by 18.000.000 to get float value
  let floatMetrics = new Array<BigDecimal>(0);
  for (let i = 0; i < event.params.metrics.length; i++) {
    floatMetrics.push(
      BigDecimal.fromString(event.params.metrics[i].toString()).div(
        BigDecimal.fromString("1000000000000000000")
      )
    );
    log.info("metrics big decimal {}", [floatMetrics[i].toString()]);
  }

  modelRegistered!.metrics = floatMetrics;
  metricsRun.save();
  modelRegistered!.save();
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
  modelRegistered.modelURI = event.params.modelURI;
  modelRegistered.metrics = new Array<BigDecimal>(0);
  modelRegistered.numberOfInferences = 0;
  modelRegistered.save();
}

function getModelIdFromEventParams(verifier: Bytes): string {
  return verifier.toHexString();
}

function getInferenceIdFromEventParams(verifier: Bytes, proof: Bytes): string {
  return verifier.toHexString() + proof.toHexString();
}

function getMetricsIdFromEventParams(verifier: Bytes, txHash: Bytes): string {
  return verifier.toHexString() + txHash.toHexString();
}
