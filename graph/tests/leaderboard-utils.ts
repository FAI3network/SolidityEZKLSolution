import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Bytes, Address } from "@graphprotocol/graph-ts"
import {
  InferenceVerified,
  MetricsRun,
  ModelDeleted,
  ModelRegistered
} from "../generated/Leaderboard/Leaderboard"

export function createInferenceVerifiedEvent(
  modelId: BigInt,
  proof: Bytes,
  instances: Array<BigInt>,
  prover: Address
): InferenceVerified {
  let inferenceVerifiedEvent = changetype<InferenceVerified>(newMockEvent())

  inferenceVerifiedEvent.parameters = new Array()

  inferenceVerifiedEvent.parameters.push(
    new ethereum.EventParam(
      "modelId",
      ethereum.Value.fromUnsignedBigInt(modelId)
    )
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
  modelId: BigInt,
  metrics: Array<BigInt>,
  nullifier: Bytes
): MetricsRun {
  let metricsRunEvent = changetype<MetricsRun>(newMockEvent())

  metricsRunEvent.parameters = new Array()

  metricsRunEvent.parameters.push(
    new ethereum.EventParam(
      "modelId",
      ethereum.Value.fromUnsignedBigInt(modelId)
    )
  )
  metricsRunEvent.parameters.push(
    new ethereum.EventParam(
      "metrics",
      ethereum.Value.fromUnsignedBigIntArray(metrics)
    )
  )
  metricsRunEvent.parameters.push(
    new ethereum.EventParam(
      "nullifier",
      ethereum.Value.fromFixedBytes(nullifier)
    )
  )

  return metricsRunEvent
}

export function createModelDeletedEvent(
  modelId: BigInt,
  verifier: Address,
  owner: Address
): ModelDeleted {
  let modelDeletedEvent = changetype<ModelDeleted>(newMockEvent())

  modelDeletedEvent.parameters = new Array()

  modelDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "modelId",
      ethereum.Value.fromUnsignedBigInt(modelId)
    )
  )
  modelDeletedEvent.parameters.push(
    new ethereum.EventParam("verifier", ethereum.Value.fromAddress(verifier))
  )
  modelDeletedEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )

  return modelDeletedEvent
}

export function createModelRegisteredEvent(
  modelId: BigInt,
  verifier: Address,
  owner: Address
): ModelRegistered {
  let modelRegisteredEvent = changetype<ModelRegistered>(newMockEvent())

  modelRegisteredEvent.parameters = new Array()

  modelRegisteredEvent.parameters.push(
    new ethereum.EventParam(
      "modelId",
      ethereum.Value.fromUnsignedBigInt(modelId)
    )
  )
  modelRegisteredEvent.parameters.push(
    new ethereum.EventParam("verifier", ethereum.Value.fromAddress(verifier))
  )
  modelRegisteredEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )

  return modelRegisteredEvent
}
