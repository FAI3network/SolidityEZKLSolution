import { newMockEvent } from "matchstick-as"
import { ethereum, Address, Bytes, BigInt } from "@graphprotocol/graph-ts"
import {
  InferenceVerified,
  MetricsRun,
  ModelDeleted,
  ModelRegistered
} from "../generated/Leaderboard/Leaderboard"

export function createInferenceVerifiedEvent(
  verifier: Address,
  proof: Bytes,
  instances: Array<BigInt>,
  prover: Address
): InferenceVerified {
  let inferenceVerifiedEvent = changetype<InferenceVerified>(newMockEvent())

  inferenceVerifiedEvent.parameters = new Array()

  inferenceVerifiedEvent.parameters.push(
    new ethereum.EventParam("verifier", ethereum.Value.fromAddress(verifier))
  )
  inferenceVerifiedEvent.parameters.push(
    new ethereum.EventParam("proof", ethereum.Value.fromBytes(proof))
  )
  inferenceVerifiedEvent.parameters.push(
    new ethereum.EventParam(
      "instances",
      ethereum.Value.fromUnsignedBigIntArray(instances)
    )
  )
  inferenceVerifiedEvent.parameters.push(
    new ethereum.EventParam("prover", ethereum.Value.fromAddress(prover))
  )

  return inferenceVerifiedEvent
}

export function createMetricsRunEvent(
  verifier: Address,
  metrics: Array<BigInt>
): MetricsRun {
  let metricsRunEvent = changetype<MetricsRun>(newMockEvent())

  metricsRunEvent.parameters = new Array()

  metricsRunEvent.parameters.push(
    new ethereum.EventParam("verifier", ethereum.Value.fromAddress(verifier))
  )
  metricsRunEvent.parameters.push(
    new ethereum.EventParam(
      "metrics",
      ethereum.Value.fromSignedBigIntArray(metrics)
    )
  )

  return metricsRunEvent
}

export function createModelDeletedEvent(
  verifier: Address,
  owner: Address
): ModelDeleted {
  let modelDeletedEvent = changetype<ModelDeleted>(newMockEvent())

  modelDeletedEvent.parameters = new Array()

  modelDeletedEvent.parameters.push(
    new ethereum.EventParam("verifier", ethereum.Value.fromAddress(verifier))
  )
  modelDeletedEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )

  return modelDeletedEvent
}

export function createModelRegisteredEvent(
  verifier: Address,
  owner: Address,
  modelURI: string
): ModelRegistered {
  let modelRegisteredEvent = changetype<ModelRegistered>(newMockEvent())

  modelRegisteredEvent.parameters = new Array()

  modelRegisteredEvent.parameters.push(
    new ethereum.EventParam("verifier", ethereum.Value.fromAddress(verifier))
  )
  modelRegisteredEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  modelRegisteredEvent.parameters.push(
    new ethereum.EventParam("modelURI", ethereum.Value.fromString(modelURI))
  )

  return modelRegisteredEvent
}
