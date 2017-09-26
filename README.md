# Base Smart Contracts

We use [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) smart contracts as base for some of Papyrus smart contracts. Currently commit 725ed40a57e8973b3ae6e2f39f9c887d0056ca39 is used.

Also we use [MultiSigWalletWithDailyLimit](https://github.com/gnosis/MultiSigWallet) implementation from Gnosis as base for Papyrus wallet. Commit c23be004ad993248281805303278abe14c410c8d is used.

## MultiAccess.sol

Implements base smart contract that stores whitelist of addresses and boolean values that are true if an address should have access to some actions on child smart contracts.

#### Events

- `AccessGranted` - arises when access is changed for some of addresses. Has following arguments:
  - `to` (`address`) - address for which access is changed.
  - `access` (`bool`) - new value of access.

#### Modificators

- `accessGranted` - fails if sender has no access. Never fails for *owner* of smart contract.

#### Functions

- `grantAccess` - grants access to specified address. Can be used only by *owner*. Has following arguments:
  - `_to` (`address`) - address for which access should be changed.
  - `_access` (`bool`) - address receives access when `true` and loses when `false`.

# Papyrus Smart Contracts

## PrePapyrusToken.sol

Implements ERC20 token. It is inherited from [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) smart contract `MintableToken`. It is also inherited from common smart contract `MultiAccess` which allows to set up addresses which have access to call `burn()` function.

It has hardcoded name **Pre-Papyrus Token** and symbol **PRP** with **18 decimals** (just like ETH and many other tokens).

PRP token is not transferable from the creation. This can be changed later using function `setTransferable()` by *owner* of smart contract.

PRP token has ability to be burned (destroyed). To do that PRP holder should call function `burn()` with specified amount of PRP tokens that should be burned. Burning tokens should work only for addresses registered as access owners.

It is not expected that PRP holders will use function `burn()` directly. Function is supported to allow exchange PRP tokens to PPR tokens. There will be smart contract that will be anounced later and will support some `exchange()` function. This function can be used by any PRP holder. To guarantee burning PRP tokens after exchange they firstly will be moved from PRP holder address to smart contract address that implements function `exchange()` using `delegatecall`. Then smart contract will call `burn()` function from PrePapyrusToken smart contract and burn just exchanged PRP tokens before sending PPR tokens back.

#### Events

- `TransferableChanged` - arises when ability to transfer tokens by holders is changed. Has following arguments:
  - `transferable` (`bool`) - new transferable value.
- `TokensBurned` - arises when token holder burns some amount of tokens. Has following arguments:
  - `from` (`address`) - address for which tokens were burned.
  - `amount` (`uint256`) - amount of burned tokens.

#### Functions

- `setTransferable` - changes ability to transfer tokens by holders. Can be used only by *owner*. Has following arguments:
  - `_transferable` (`bool`) - token becomes transferable when `true` and not transferable when `false`.
- `burn` - burns (destroys) tokens from sender address with specified amount. Has following arguments:
  - `_amount` (`uint256`) - amount of tokens should be burned.
