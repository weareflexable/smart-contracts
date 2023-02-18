import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt, Bytes } from "@graphprotocol/graph-ts"
import {
  Approval,
  ApprovalForAll,
  Paused,
  RoleAdminChanged,
  RoleGranted,
  RoleRevoked,
  RoyaltyUpdated,
  TicketBurnt,
  TicketCreated,
  TicketRedeemed,
  Transfer,
  Unpaused
} from "../generated/FlexableNFT/FlexableNFT"

export function createApprovalEvent(
  owner: Address,
  approved: Address,
  tokenId: BigInt
): Approval {
  let approvalEvent = changetype<Approval>(newMockEvent())

  approvalEvent.parameters = new Array()

  approvalEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam("approved", ethereum.Value.fromAddress(approved))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return approvalEvent
}

export function createApprovalForAllEvent(
  owner: Address,
  operator: Address,
  approved: boolean
): ApprovalForAll {
  let approvalForAllEvent = changetype<ApprovalForAll>(newMockEvent())

  approvalForAllEvent.parameters = new Array()

  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("operator", ethereum.Value.fromAddress(operator))
  )
  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("approved", ethereum.Value.fromBoolean(approved))
  )

  return approvalForAllEvent
}

export function createPausedEvent(account: Address): Paused {
  let pausedEvent = changetype<Paused>(newMockEvent())

  pausedEvent.parameters = new Array()

  pausedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )

  return pausedEvent
}

export function createRoleAdminChangedEvent(
  role: Bytes,
  previousAdminRole: Bytes,
  newAdminRole: Bytes
): RoleAdminChanged {
  let roleAdminChangedEvent = changetype<RoleAdminChanged>(newMockEvent())

  roleAdminChangedEvent.parameters = new Array()

  roleAdminChangedEvent.parameters.push(
    new ethereum.EventParam("role", ethereum.Value.fromFixedBytes(role))
  )
  roleAdminChangedEvent.parameters.push(
    new ethereum.EventParam(
      "previousAdminRole",
      ethereum.Value.fromFixedBytes(previousAdminRole)
    )
  )
  roleAdminChangedEvent.parameters.push(
    new ethereum.EventParam(
      "newAdminRole",
      ethereum.Value.fromFixedBytes(newAdminRole)
    )
  )

  return roleAdminChangedEvent
}

export function createRoleGrantedEvent(
  role: Bytes,
  account: Address,
  sender: Address
): RoleGranted {
  let roleGrantedEvent = changetype<RoleGranted>(newMockEvent())

  roleGrantedEvent.parameters = new Array()

  roleGrantedEvent.parameters.push(
    new ethereum.EventParam("role", ethereum.Value.fromFixedBytes(role))
  )
  roleGrantedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  roleGrantedEvent.parameters.push(
    new ethereum.EventParam("sender", ethereum.Value.fromAddress(sender))
  )

  return roleGrantedEvent
}

export function createRoleRevokedEvent(
  role: Bytes,
  account: Address,
  sender: Address
): RoleRevoked {
  let roleRevokedEvent = changetype<RoleRevoked>(newMockEvent())

  roleRevokedEvent.parameters = new Array()

  roleRevokedEvent.parameters.push(
    new ethereum.EventParam("role", ethereum.Value.fromFixedBytes(role))
  )
  roleRevokedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  roleRevokedEvent.parameters.push(
    new ethereum.EventParam("sender", ethereum.Value.fromAddress(sender))
  )

  return roleRevokedEvent
}

export function createRoyaltyUpdatedEvent(
  reciever: Address,
  percentageBasisPoint: BigInt
): RoyaltyUpdated {
  let royaltyUpdatedEvent = changetype<RoyaltyUpdated>(newMockEvent())

  royaltyUpdatedEvent.parameters = new Array()

  royaltyUpdatedEvent.parameters.push(
    new ethereum.EventParam("reciever", ethereum.Value.fromAddress(reciever))
  )
  royaltyUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "percentageBasisPoint",
      ethereum.Value.fromUnsignedBigInt(percentageBasisPoint)
    )
  )

  return royaltyUpdatedEvent
}

export function createTicketBurntEvent(
  tokenId: BigInt,
  ownerOrApproved: Address
): TicketBurnt {
  let ticketBurntEvent = changetype<TicketBurnt>(newMockEvent())

  ticketBurntEvent.parameters = new Array()

  ticketBurntEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  ticketBurntEvent.parameters.push(
    new ethereum.EventParam(
      "ownerOrApproved",
      ethereum.Value.fromAddress(ownerOrApproved)
    )
  )

  return ticketBurntEvent
}

export function createTicketCreatedEvent(
  tokenID: BigInt,
  creator: Address,
  metaDataURI: string
): TicketCreated {
  let ticketCreatedEvent = changetype<TicketCreated>(newMockEvent())

  ticketCreatedEvent.parameters = new Array()

  ticketCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenID",
      ethereum.Value.fromUnsignedBigInt(tokenID)
    )
  )
  ticketCreatedEvent.parameters.push(
    new ethereum.EventParam("creator", ethereum.Value.fromAddress(creator))
  )
  ticketCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "metaDataURI",
      ethereum.Value.fromString(metaDataURI)
    )
  )

  return ticketCreatedEvent
}

export function createTicketRedeemedEvent(
  tokenID: BigInt,
  count: i32,
  info: string
): TicketRedeemed {
  let ticketRedeemedEvent = changetype<TicketRedeemed>(newMockEvent())

  ticketRedeemedEvent.parameters = new Array()

  ticketRedeemedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenID",
      ethereum.Value.fromUnsignedBigInt(tokenID)
    )
  )
  ticketRedeemedEvent.parameters.push(
    new ethereum.EventParam(
      "count",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(count))
    )
  )
  ticketRedeemedEvent.parameters.push(
    new ethereum.EventParam("info", ethereum.Value.fromString(info))
  )

  return ticketRedeemedEvent
}

export function createTransferEvent(
  from: Address,
  to: Address,
  tokenId: BigInt
): Transfer {
  let transferEvent = changetype<Transfer>(newMockEvent())

  transferEvent.parameters = new Array()

  transferEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return transferEvent
}

export function createUnpausedEvent(account: Address): Unpaused {
  let unpausedEvent = changetype<Unpaused>(newMockEvent())

  unpausedEvent.parameters = new Array()

  unpausedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )

  return unpausedEvent
}
