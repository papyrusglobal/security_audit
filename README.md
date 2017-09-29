# Base Smart Contracts

We use [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) smart contracts as base for some of Papyrus smart contracts. Currently commit 725ed40a57e8973b3ae6e2f39f9c887d0056ca39 is used.

Also we use [MultiSigWalletWithDailyLimit](https://github.com/gnosis/MultiSigWallet) implementation from Gnosis as base for Papyrus wallet. Commit c23be004ad993248281805303278abe14c410c8d is used.

# Papyrus Smart Contracts

## PapyrusPrototypeToken.sol

Implements ERC20 token. It is inherited from [OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) `StandardToken` and `Ownable` smart contracts.

It has hardcoded name **Papyrus Prototype Token** and symbol **PRP** with **18 decimals** (just like ETH and many other tokens).

PRP token is not transferable from the creation. This can be changed later using function `setTransferable()` by *owner* of smart contract.

Smart contract has public variable `totalCollected`. It accumulates amount of received USD during Token Generation Event. To calculate this value in USD when calling `mint` function we specify `_priceUsd` value used at moment of participation. Value **0** can be used for tokens that are minted not as part of Token Generation Event (tokens minted for bounty, etc.). Adding `_priceUsd` argument and `totalCollected` calculation logic is the reason the contract implements mintable behavior directly rather than inheriting from OpenZeppelin `MintableToken`.

#### Events

- `Mint` - arises when tokens are minted. Has following arguments:
  - `to` (`address`) - address which gets minted tokens.
  - `amount` (`uint256`) - amount of minted tokens.
- `MintFinished` - arises when minting tokens is over. It is not possible to mint tokens after event is happened.
- `TransferableChanged` - arises when ability to transfer tokens by holders is changed. Has following arguments:
  - `transferable` (`bool`) - new transferable value.

#### Functions

- `mint` - mints (creates) tokens and store them at specified address. Can be used only by *owner* until minting is finished. Has following arguments:
  - `_to` (`address`) - address which gets minted tokens.
  - `_amount` (`uint256`) - amount of minted tokens.
  - `_priceUsd` (`uint256`) - price for 1 token in USD. Please note that 18 decimals value is expected. For example, if price for 1 token is $0.8 then value as 0.8 ETH in weis should be used.
- `finishMinting` - finishes minting and denying further minting tokens. Can be used only by *owner* until minting is finished.
- `setTransferable` - changes ability to transfer tokens by holders. Can be used only by *owner*. Has following arguments:
  - `_transferable` (`bool`) - token becomes transferable when `true` and not transferable when `false`.
