pragma solidity ^0.4.15;

import "./zeppelin/token/MintableToken.sol";
import "./MultiAccess.sol";

/// @title Pre-Papyrus token smart contract (PRP).
contract PrePapyrusToken is MintableToken, MultiAccess {
    using SafeMath for uint256;

    // EVENTS

    event TransferableChanged(bool transferable);
    event TokensBurned(address indexed from, uint256 amount);

    // PUBLIC FUNCTIONS

    // If ether is sent to this address, send it back
    function() { revert(); }

    // Check transfer ability and sender address before transfer
    function transfer(address _to, uint _value) canTransfer returns (bool) {
        return super.transfer(_to, _value);
    }

    // Check transfer ability and sender address before transfer
    function transferFrom(address _from, address _to, uint _value) canTransfer returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// @dev Change ability to transfer tokens by users.
    function setTransferable(bool _transferable) onlyOwner {
        require(transferable != _transferable);
        transferable = _transferable;
        TransferableChanged(transferable);
    }

    /// @dev Burns (destroys) tokens from sender address with specified amount.
    /// @param _amount Amount of tokens should be burned.
    function burn(uint256 _amount) accessGranted {
        address from = msg.sender;
        require(balances[from] >= _amount);
        balances[from] = balances[from].sub(_amount);
        burnedTokens = burnedTokens.add(_amount);
        TokensBurned(from, _amount);
    }

    // MODIFIERS

    modifier canTransfer() {
        require(transferable || msg.sender == owner || accessGrants[msg.sender]);
        _;
    }

    // FIELDS

    // Standard fields used to describe the token
    string public name = "Pre-Papyrus Token";
    string public symbol = "PRP";
    string public version = "H0.1";
    uint8 public decimals = 18;

    // Amount of burned (destroyed) tokens
    uint256 public burnedTokens;

    // At the start of the token existence token is not transferable
    bool public transferable = false;
}
