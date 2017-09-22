pragma solidity ^0.4.11;

import "./gnosis/MultiSigWalletWithDailyLimit.sol";

/// @title Multisignature wallet with daily limit - Allows an owner to withdraw a daily limit without multisig.
contract PapyrusWallet is MultiSigWalletWithDailyLimit {

    /// @dev Contract constructor sets initial owners, required number of confirmations and daily withdraw limit.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    function PapyrusWallet(address[] _owners, uint _required, uint _dailyLimit)
        public
        MultiSigWalletWithDailyLimit(_owners, _required, _dailyLimit)
    {
    }

    /// @dev Allows an owner to submit and confirm a batch of transactions.
    /// @param destinations Transactions target addresses.
    /// @param values Transactions ether values.
    /// @param dataOffsets Transactions data offsets used to grab needed data.
    /// @param dataLengths Transactions data length used to grab needed data.
    /// @param data Transactions data payloads.
    function submitTransactions(address[] destinations, uint[] values, uint[] dataOffsets, uint[] dataLengths, bytes data) public {
        require(destinations.length == values.length);
        require(destinations.length == dataOffsets.length);
        require(destinations.length == dataLengths.length);
        uint j;
        for (uint i = 0; i < destinations.length; ++i) {
            uint dataOffset = dataOffsets[i];
            uint dataLength = dataLengths[i];
            require(dataLength == 0 || dataOffset + dataLength <= data.length);
            bytes memory dataTransaction = new bytes(dataLength);
            for (j = 0; j < dataLength; ++j) {
                dataTransaction[j] = data[dataOffset + j];
            }
            submitTransaction(destinations[i], values[i], dataTransaction);
        }
    }

    /// @dev Allows an owner to confirm a batch of transactions.
    /// @param transactionIds Transaction IDs.
    function confirmTransactions(uint[] transactionIds) public {
        for (uint i = 0; i < transactionIds.length; ++i) {
            confirmTransaction(transactionIds[i]);
        }
    }
}
