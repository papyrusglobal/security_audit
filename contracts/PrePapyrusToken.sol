pragma solidity ^0.4.11;

import "./zeppelin/token/StandardToken.sol";
import "./MultiAccess.sol";

/// @title Pre-Papyrus token contract (PRP) including pre-sale support.
contract PrePapyrusToken is StandardToken, MultiAccess {
    using SafeMath for uint256;

    // EVENTS

    event TransferableChanged(bool transferable);
    event TokensBurned(address indexed from, uint256 amount);

    // PUBLIC FUNCTIONS

    /// @dev Contract constructor function.
    /// @param _wallets List of wallets addresses used to store some tokens at creation time.
    /// @param _amounts List of token amounts to store.
    function PrePapyrusToken(address[] _wallets, uint256[] _amounts) {
        require(_wallets.length == _amounts.length && _wallets.length > 0);
        uint i;
        uint256 sum = 0;
        for (i = 0; i < _wallets.length; ++i) {
            sum = sum.add(_amounts[i]);
        }
        require(sum == PRP_LIMIT);
        totalSupply = PRP_LIMIT;
        for (i = 0; i < _wallets.length; ++i) {
            balances[_wallets[i]] = _amounts[i];
        }
    }

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
    function setTransferable(bool _transferable) accessGranted {
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

    // Amount of supplied tokens is constant and equals to 50,000,000 PRP
    uint256 private constant PRP_LIMIT = 5 * 10**25;
}
