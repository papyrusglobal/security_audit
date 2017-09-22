# Base Smart Contracts

We use [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) smart contracts as base for some of Papyrus smart contracts. Currently commit 725ed40a57e8973b3ae6e2f39f9c887d0056ca39 is used.

Also we use [MultiSigWalletWithDailyLimit](https://github.com/gnosis/MultiSigWallet) implementation from Gnosis as base for Papyrus wallet. Commit 4b98bdfd9a375538491cd3ece7c2fdf8f857291d is used.

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
  - `_access` (`bool`) - address receives access when `True` and loses when `False`.

# Papyrus Smart Contracts

## PapyrusWallet.sol

As the base for Papyrus wallet we have chosen [MultiSigWalletWithDailyLimit](https://github.com/gnosis/MultiSigWallet) implementation from Gnosis.

However, we have added two additional functions `submitTransactions()` and `confirmTransactions()`. These functions are just batch versions of existing `submitTransaction()` and `confirmTransaction()` functions respectively. These functions can be used to submit or confirm several transactions per one call.

#### Functions

- `submitTransactions` - allows an owner to submit and confirm a batch of transactions. Can be used only by one of *owners of wallet*. Has following arguments:
  - `destinations` (`address[]`) - transactions target addresses.
  - `values` (`uint[]`) - transactions ether values.
  - `dataOffsets` (`uint[]`) - transactions data offsets used to grab needed data.
  - `dataLengths` (`uint[]`) - transactions data length used to grab needed data.
  - `data` (`bytes`) - transactions data payloads.
- `confirmTransactions` - allows an owner to confirm a batch of transactions. Can be used only by one of *owners of wallet*. Has following arguments:
  - `transactionIds` (`uint[]`) - transaction IDs.

## PrePapyrusToken.sol

Implements ERC20 token. It is inherited from [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) smart contract `StandardToken`. It is also inherited from common smart contract `MultiAccess` which allows to set up addresses which have access to call `setTransferable()` and `burn()` functions.

It has hardcoded name **Pre-Papyrus Token** and symbol **PRP** with **18 decimals** (just like ETH and many other tokens).

This is not mintable token which means that there are pre-defined amount of PRP created – **50,000,000 (fifty million)** units. Since these values are hardcoded and cannot be changed and tokens cannot be supplied, there will never be more than 50,000,000 PRP in the system.

When token smart contract is created this is guaranteed by checking in construction function that all of created tokens are distibuted to specified wallets.

PRP token is not transferable from the creation. This can be changed later using function `setTransferable()` from *owner* address.

PRP token has ability to be burned (destroyed). To do that any PRP holder should call function `burn()` with specified amount of PRP tokens that should be burned.

#### Events

- `TransferableChanged` - arises when ability to transfer tokens by holders is changed. Has following arguments:
  - `transferable` (`bool`) - new transferable value.
- `TokensBurned` - arises when token holder burns some amount of tokens. Has following arguments:
  - `from` (`address`) - address for which tokens were burned.
  - `amount` (`uint256`) - amount of burned tokens.

#### Functions

- `setTransferable` - changes ability to transfer tokens by holders. Can be used only by *owner*. Has following arguments:
  - `_transferable` (`bool`) - token becomes transferable when `True` and not transferable when `False`.
- `burn` - burns (destroys) tokens from sender address with specified amount. Has following arguments:
  - `_amount` (`uint256`) - amount of tokens should be burned.

## PapyrusToken.sol

Implements ERC20 token. It is inherited from [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) smart contract `StandardToken`. It is also inherited from smart contract `Ownable` which allows to deny calling `setTransferable()` function from any address except *owner*.

It has hardcoded name **Papyrus Token** and symbol **PPR** with **18 decimals** (just like ETH and many other tokens).

This is not mintable token which means that there are pre-defined amount of PPR created – **1,000,000,000 (one billion)** units. Since these values are hardcoded and cannot be changed and tokens cannot be supplied, there will never be more than 1,000,000,000 PPR in the system.

When token smart contract is created this is guaranteed by checking in construction function that all of created tokens are distibuted to specified wallets.

PPR token is transferable from the creation. This can be changed later using function `setTransferable()` from *owner* address.

#### Events

- `TransferableChanged` - arises when ability to transfer tokens by holders is changed. Has following arguments:
  - `transferable` (`bool`) - new transferable value.

#### Functions

- `setTransferable` - changes ability to transfer tokens by holders. Can be used only by *owner*. Has following arguments:
  - `_transferable` (`bool`) - token becomes transferable when `True` and not transferable when `False`.

# Usage

For now only simples usage of Papyrus Wallet is presented. It can be found in file *test/python/PapyrusWalletTest.py*.