import {
  RoleGranted,
  RoleRevoked,
  StatusUpdated,
  TicketCreated,
  Transfer
} from "../generated/FlexableNFT/FlexableNFT"
import { Token, User } from "../generated/schema"
export function handleTransfer(event: Transfer): void {
  let token = Token.load(event.params.tokenId.toString());
  if (token) {
    token.createdAtTimestamp = event.block.timestamp
    token.owner = event.params.to.toHexString();
    token.save();

    let user = User.load(event.params.to.toHexString());
    token.save();
    if (!user) {
      user = new User(event.params.to.toHexString());
      user.save();
    }
  }
}

export function handleArtifactCreated(event: TicketCreated): void {
  let token = Token.load(event.params.tokenID.toString());
  if (!token) {
    token = new Token(event.params.tokenID.toString())
    token.creator = event.params.creator.toHexString()
    token.createdAtTimestamp = event.block.timestamp
    token.owner = event.params.creator.toHexString();
    token.metaDataUri = event.params.metaDataUri
    token.status = ""
    let user = User.load(event.params.creator.toHexString());
    token.save();
    if (!user) {
      user = new User(event.params.creator.toHexString());
      user.save();
    }
  }
}


export function handleRoleGranted(event: RoleGranted): void {
  let user = User.load(event.params.account.toHexString());
  if (!user) {
    user = new User(event.params.account.toHexString());
  }
  let userHasRole = user.roles.includes(event.params.role.toHexString())
  if (!userHasRole) {
    let updatedRoles = user.roles
    updatedRoles.push(event.params.role.toHexString())
    user.roles = updatedRoles
  }
  user.save();
}

export function handleRoleRevoked(event: RoleRevoked): void {
  let user = User.load(event.params.account.toHexString());
  if (!user) {
    user = new User(event.params.account.toHexString());
  }

  let idx = user.roles.indexOf(event.params.role.toHexString())
  if (idx >= 0) {
    let updatedRoles = user.roles;
    updatedRoles.splice(idx, 1)
    user.roles = updatedRoles
    user.save();
  }
}

export function handleStatusUpdates(event: StatusUpdated): void {
  let token = Token.load(event.params.tokenID.toString());
  if (token) {
    token.status = event.params.status
    token.save()
  }
}