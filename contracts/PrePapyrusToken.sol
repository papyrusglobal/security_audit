pragma solidity ^0.4.11;

import "./zeppelin/token/StandardToken.sol";
import "./MultiAccess.sol";
import "./PrivateParticipation.sol";
import "./PapyrusKYC.sol";

/// @title Pre-Papyrus token contract (PRP) including pre-sale support.
contract PrePapyrusToken is StandardToken, PrivateParticipation, MultiAccess {
    using SafeMath for uint256;

    // TYPES

    enum Stage {
        TokenDeployed,
        AuctionReadyToStart,
        AuctionStartedPrivate,
        AuctionStartedPublic,
        AuctionFinished
    }

    // EVENTS

    event TokensSold(address indexed to, uint256 amount, uint128 customerId);
    event TokensBurned(address indexed from, uint256 amount);

    // PUBLIC FUNCTIONS

    /// @dev Contract constructor function.
    /// @param _kycManager Address of KYC manager contract.
    /// @param _wallets List of wallets addresses used to store some tokens at creation time.
    /// @param _amounts List of token amounts to store.
    function PrePapyrusToken(address _kycManager, address[] _wallets, uint256[] _amounts) {
        require(_wallets.length == _amounts.length && _wallets.length > 0);
        uint i;
        uint256 sum = 0;
        for (i = 0; i < _wallets.length; ++i) {
            sum = sum.add(_amounts[i]);
        }
        require(sum < PRP_LIMIT);
        totalSupply = PRP_LIMIT;
        kycManager = PapyrusKYC(_kycManager);
        for (i = 0; i < _wallets.length; ++i) {
            balances[_wallets[i]] = _amounts[i];
        }
        balances[this] = PRP_LIMIT.sub(sum);
        stage = Stage.TokenDeployed;
    }

    function() public payable {
        buyTokens(msg.sender, 0);
    }

    // Check sender address before transfer
    function transfer(address _to, uint _value) accessGranted returns (bool) {
        return super.transfer(_to, _value);
    }

    // Check sender address before approve
    function approve(address _spender, uint256 _value) accessGranted returns (bool) {
        return super.approve(_spender, _value);
    }

    // Check sender address before transfer
    function transferFrom(address _from, address _to, uint _value) accessGranted returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// @dev Burns (destroys) tokens from specified address with specified amount.
    /// @param _from Address from which tokens should be burned.
    /// @param _amount Amount of tokens should be burned.
    function burn(address _from, uint256 _amount) accessGranted {
        require(balances[_from] >= _amount);
        balances[_from] = balances[_from].sub(_amount);
        burnedTokens = burnedTokens.add(_amount);
        TokensBurned(_from, _amount);
    }

    /// @dev Changes auction settings.
    /// @param _wallet Papyrus multi-signature wallet address for storing ETH during auction.
    /// @param _ceiling Auction ceiling in weis.
    /// @param _priceEther Current price ETH/USD.
    /// @param _priceToken Price of the token as PRP/ETH.
    /// @param _bonusPercent Percent of bonus tokens we share with private participants of the auction.
    /// @param _minPrivateBid Minimal amount of weis for private participants of the auction.
    /// @param _minPublicBid Minimal amount of weis for public participants of the auction.
    /// @param _auctionPrivateStart Index of block from which private auction should be started.
    /// @param _auctionPublicStart Index of block from which public auction should be started.
    /// @param _auctionFinish Index of block from which auction should be finished.
    function setupAuction(
        address _wallet,
        uint256 _ceiling,
        uint256 _priceEther,
        uint256 _priceToken,
        uint8   _bonusPercent,
        uint256 _minPrivateBid,
        uint256 _minPublicBid,
        uint256 _auctionPrivateStart,
        uint256 _auctionPublicStart,
        uint256 _auctionFinish
    )
        onlyOwner
    {
        require(stage == Stage.TokenDeployed || stage == Stage.AuctionReadyToStart);
        require(_wallet != address(0) && _ceiling != 0 && _priceEther != 0 && _priceToken != 0);
        require(_auctionPrivateStart <= _auctionPublicStart && _auctionPublicStart <= _auctionFinish);
        require(_auctionPrivateStart > block.number);
        require(balanceOf(this) > 0);
        ceiling = _ceiling;
        priceEther = _priceEther;
        priceToken = _priceToken;
        bonusPercent = _bonusPercent;
        minPrivateBid = _minPrivateBid;
        minPublicBid = _minPublicBid;
        auctionPrivateStart = _auctionPrivateStart;
        auctionPublicStart = _auctionPublicStart;
        auctionFinish = _auctionFinish;
        tokensToSell = balanceOf(this).mul(100).div(100 + bonusPercent);
        tokensBonus = balanceOf(this).sub(tokensToSell);
        require(tokensToSell.mul(E18).div(priceToken) >= _ceiling);
        stage = Stage.AuctionReadyToStart;
    }

    /// @dev Sets private auction start block index.
    function setPrivateAuctionStart(uint256 _blockIndex)
        onlyOwner
        timedTransitions
    {
        require(stage == Stage.AuctionReadyToStart);
        require(_blockIndex <= auctionPublicStart);
        auctionPrivateStart = _blockIndex;
    }

    /// @dev Sets public auction start block index.
    function setPublicAuctionStart(uint256 _blockIndex)
        onlyOwner
        timedTransitions
    {
        require(stage >= Stage.AuctionReadyToStart && stage < Stage.AuctionStartedPublic);
        require(auctionPrivateStart <= _blockIndex && _blockIndex <= auctionFinish);
        auctionPublicStart = _blockIndex;
    }

    /// @dev Sets auction finishing block index.
    function setAuctionFinish(uint256 _blockIndex)
        onlyOwner
        timedTransitions
    {
        require(stage >= Stage.AuctionReadyToStart && stage < Stage.AuctionFinished);
        require(_blockIndex >= auctionPublicStart);
        auctionFinish = _blockIndex;
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not been called yet.
    /// @return Returns current auction stage.
    function updateStage()
        timedTransitions
        returns (Stage)
    {
        return stage;
    }

    /// @dev Allows to send a bid to the auction.
    /// @param receiver Tokens will be assigned to this address if set.
    /// @param customerId (optional) UUID v4 to track the successful payments on the server side.
    function buyTokens(address receiver, uint128 customerId)
        payable
        isValidPayload
        timedTransitions
        returns (uint256 amount)
    {
        require(stage >= Stage.AuctionStartedPrivate && stage < Stage.AuctionFinished);
        require(msg.value > 0);
        // If a bid is done on behalf of a user via ShapeShift, the receiver address is set
        if (receiver == address(0))
            receiver = msg.sender;
        // Check some conditions depending on stage of the auction
        uint256 amountAllowedPrivate = privateParticipants[receiver].sub(receivedBids[receiver]);
        if (stage == Stage.AuctionStartedPrivate) {
            // allow bids only from private participants addresses
            require(amountAllowedPrivate != 0 && amount >= minPrivateBid);
        } else if (stage == Stage.AuctionStartedPublic) {
            // disallow bids from private participants addresses
            require(amountAllowedPrivate == 0 && amount >= minPublicBid);
        } else {
            revert();
        }
        // Prevent that more than specified amount of tokens are sold. Only relevant if cap not reached.
        uint256 maxWei = tokensToSell.sub(tokensSold).mul(E18).div(priceToken);
        uint256 maxWeiBasedOnTotalReceived = ceiling.sub(totalReceived);
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;
        if (stage == Stage.AuctionStartedPrivate && amountAllowedPrivate < maxWei)
            maxWei = amountAllowedPrivate;
        // Only invest maximum possible amount.
        amount = msg.value;
        if (amount > maxWei) {
            amount = maxWei;
            // Send change back to receiver address. In case of a ShapeShift bid the user receives the change back directly.
            if (!receiver.send(msg.value.sub(amount))) {
                // Sending failed
                revert();
            }
        }
        if (amount == 0)
            return;
        // Forward funding to ether wallet
        if (!wallet.send(amount)) {
            // Sending failed
            revert();
        }
        uint256 amountTokens = amount.mul(priceToken).div(E18);
        if (amountAllowedPrivate > 0) {
            // Add bonus tokens for private participants
            amountTokens = amountTokens.mul(100 + bonusPercent).div(100);
        }
        balances[receiver] = balances[receiver].add(amountTokens);
        kycManager.setKycRequirement(receiver, true);
        tokensSold = tokensSold.add(amountTokens);
        if (receivedBids[receiver] == 0) {
            participants.push(receiver);
            ++participantCount;
        }
        receivedBids[receiver] = receivedBids[receiver].add(amount);
        if (stage == Stage.AuctionStartedPrivate) {
            privateReceived = privateReceived.add(amount);
        } else if (stage == Stage.AuctionStartedPublic) {
            publicReceived = publicReceived.add(amount);
        }
        totalReceived = totalReceived.add(amount);
        if (maxWei == amount) {
            // When maxWei is equal to the big amount the auction is ended and finalizeAuction is triggered.
            finalizeAuction();
        }
        TokensSold(receiver, amountTokens, customerId);
    }

    // PRIVATE FUNCTIONS

    function finalizeAuction() private {
        uint256 tokensRemaining = tokensToSell.sub(tokensSold);
        if (tokensRemaining > 0) {
            // Auction contract burns all unsold tokens
            burn(this, tokensRemaining);
        }
        stage = Stage.AuctionFinished;
    }

    // MODIFIERS

    modifier atStage(Stage _stage) {
        require(stage == _stage);
        _;
    }

    modifier isValidPayload() {
        // TODO: Why is this necessary?
        //require(msg.data.length == 4 || msg.data.length == 36);
        _;
    }

    modifier timedTransitions() {
        if (stage == Stage.AuctionReadyToStart && block.number >= auctionPrivateStart)
            stage = Stage.AuctionStartedPrivate;
        if (stage == Stage.AuctionStartedPrivate && block.number >= auctionPublicStart)
            stage = Stage.AuctionStartedPublic;
        if (stage == Stage.AuctionStartedPublic && block.number >= auctionFinish)
            finalizeAuction();
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

    // Address to KYC manager contract
    PapyrusKYC public kycManager;

    // Amount of tokens expected to be sold during whole auction
    uint256 public tokensToSell;

    // Amount of tokens used only as bonus tokens for private participants
    uint256 public tokensBonus;

    // Amount of tokens already sold
    uint256 public tokensSold;

    // Percent of bonus tokens we share with private participants of the auction
    uint256 public bonusPercent;

    // Minimal amount of weis for private participants of the auction
    uint256 public minPrivateBid;

    // Minimal amount of weis for public participants of the auction
    uint256 public minPublicBid;

    // Address of multisig wallet used to hold received ether
    address public wallet;

    // Auction ceiling in weis
    uint256 public ceiling;

    // Price ETH/USD at the start of auction
    uint256 public priceEther;

    // Price PRP/ETH at the start of auction
    uint256 public priceToken;

    // Index of block from which private auction should be started
    uint256 public auctionPrivateStart;

    // Index of block from which public auction should be started
    uint256 public auctionPublicStart;

    // Index of block from which auction should be finished
    uint256 public auctionFinish;

    // Amount of received weis at private stage
    uint256 public privateReceived;

    // Amount of received weis at public stage
    uint256 public publicReceived;

    // Amount of total received weis
    uint256 public totalReceived;

    // List of addresses of all participants of the auction
    address[] public participants;
    
    // Count of all participants of the auction
    uint256 public participantCount;

    // Received bids
    mapping (address => uint256) public receivedBids;

    // Current stage of the auction
    Stage public stage;

    // Amount of supplied tokens is constant and equals to 50 000 000 PRP
    uint256 private constant PRP_LIMIT = 5 * 10**25;

    // Some pre-calculated constant values
    uint256 private constant E18 = 10**18;
}
