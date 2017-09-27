pragma solidity ^0.4.15;

import "./zeppelin/token/MintableToken.sol";

/// @title Papyrus Prototype Token (PRP) smart contract.
contract PapyrusPrototypeToken is MintableToken {

    // EVENTS

    event TransferableChanged(bool transferable);

    // PUBLIC FUNCTIONS

    // If ether is sent to this address, send it back
    function() { revert(); }

    // Check transfer ability and sender address before transfer
    function transfer(address _to, uint _value) public canTransfer returns (bool) {
        return super.transfer(_to, _value);
    }

    // Check transfer ability and sender address before transfer
    function transferFrom(address _from, address _to, uint _value) public canTransfer returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// @dev Change ability to transfer tokens by users.
    function setTransferable(bool _transferable) public onlyOwner {
        require(transferable != _transferable);
        transferable = _transferable;
        TransferableChanged(transferable);
    }

    // MODIFIERS

    modifier canTransfer() {
        require(transferable || msg.sender == owner);
        _;
    }

    // FIELDS

    // Standard fields used to describe the token
    string public name = "Papyrus Prototype Token";
    string public symbol = "PRP";
    string public version = "H0.1";
    uint8 public decimals = 18;

    // At the start of the token existence token is not transferable
    bool public transferable = false;
}
