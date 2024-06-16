import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, Bytes, BigInt } from "@graphprotocol/graph-ts"
import { InferenceVerified } from "../generated/schema"
import { InferenceVerified as InferenceVerifiedEvent } from "../generated/Leaderboard/Leaderboard"
import { handleInferenceVerified } from "../src/leaderboard"
import { createInferenceVerifiedEvent } from "./leaderboard-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let verifier = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let proof = Bytes.fromI32(1234567890)
    let instances = [BigInt.fromI32(234)]
    let prover = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let newInferenceVerifiedEvent = createInferenceVerifiedEvent(
      verifier,
      proof,
      instances,
      prover
    )
    handleInferenceVerified(newInferenceVerifiedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("InferenceVerified created and stored", () => {
    assert.entityCount("InferenceVerified", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "InferenceVerified",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "verifier",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "InferenceVerified",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "proof",
      "1234567890"
    )
    assert.fieldEquals(
      "InferenceVerified",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "instances",
      "[234]"
    )
    assert.fieldEquals(
      "InferenceVerified",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "prover",
      "0x0000000000000000000000000000000000000001"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
