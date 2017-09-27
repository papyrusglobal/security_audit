# Base Smart Contracts

We use [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) smart contracts as base for some of Papyrus smart contracts. Currently commit 725ed40a57e8973b3ae6e2f39f9c887d0056ca39 is used.

Also we use [MultiSigWalletWithDailyLimit](https://github.com/gnosis/MultiSigWallet) implementation from Gnosis as base for Papyrus wallet. Commit c23be004ad993248281805303278abe14c410c8d is used.

# Papyrus Smart Contracts

## PapyrusPrototypeToken.sol

Implements ERC20 token. It is inherited from [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) smart contract `MintableToken`.

It has hardcoded name **Papyrus Prototype Token** and symbol **PRP** with **18 decimals** (just like ETH and many other tokens).

PRP token is not transferable from the creation. This can be changed later using function `setTransferable()` by *owner* of smart contract.

#### Events

- `TransferableChanged` - arises when ability to transfer tokens by holders is changed. Has following arguments:
  - `transferable` (`bool`) - new transferable value.

#### Functions

- `setTransferable` - changes ability to transfer tokens by holders. Can be used only by *owner*. Has following arguments:
  - `_transferable` (`bool`) - token becomes transferable when `true` and not transferable when `false`.
