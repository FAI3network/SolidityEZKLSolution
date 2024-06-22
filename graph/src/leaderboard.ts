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
  modelRegistered.avgMetrics = new Array<BigDecimal>(0);
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
  inferenceVerified.relVariables = event.params.relVariables;
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

  // log.info("metricsRun: {}", [metricsRun.id]);
  // log.info("modelRegistered: {}", [modelRegistered!.id]);
  // // log avgMetrics length
  // log.info("avgMetrics length: {}", [
  //   modelRegistered!.avgMetrics!.length.toString(),
  // ]);

  let newAvgMetrics = modelRegistered!.avgMetrics;

  if (modelRegistered!.avgMetrics!.length == 0) {
    // initialize avgMetrics
    newAvgMetrics = event.params.metrics.map<BigDecimal>((metric: BigInt) =>
      BigDecimal.fromString(metric.toString())
    );
    log.info("avgMetrics initialized: {}, avgMetrics[0] = {}", [
      newAvgMetrics.length.toString(),
      newAvgMetrics[0].toString(),
    ]);
  } else {
    // update avgMetrics : newAvg = (currentAvg * numInferences + newValue) / (numInferences + 1)
    let numInferences = BigDecimal.fromString(
      modelRegistered!.numberOfInferences.toString()
    );
    for (let i = 0; i < event.params.metrics.length; i++) {
      let currentAvg = newAvgMetrics![i];
      let newValue = event.params.metrics[i].toBigDecimal();
      // log.info("numInferences: {}", [numInferences.toString()]);
      log.info("currentAvg[{}]: {}", [i.toString(), currentAvg.toString()]);
      let newAvg = currentAvg
        .times(numInferences)
        .plus(newValue)
        .div(numInferences.plus(BigDecimal.fromString("1")));

      log.info("newAvg[{}]: {}", [i.toString(), newAvg.toString()]);
      newAvgMetrics![i] = newAvg;
    }
  }
  modelRegistered!.avgMetrics = newAvgMetrics;
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
