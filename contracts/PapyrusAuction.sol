pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/token/BasicToken.sol";

/// @title Reverse dutch auction contract - distribution of Papyrus tokens using an auction.
/// Based on dutch auction contract from Stefan George (Gnosis).
contract PapyrusAuction is Ownable {
    using SafeMath for uint256;

    // TYPES

    enum Stage {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStartedPrivate,
        AuctionStartedPublic,
        AuctionFinishing,
        AuctionFinished,
        ClaimingStarted
    }

    // EVENTS

    event BidSubmission(address indexed sender, uint256 amount);

    // PUBLIC FUNCTIONS

    /// @dev Contract constructor function.
    /// @param _wallet Papyrus multisigwallet address for storing ETH after claiming.
    /// @param _ceiling Auction ceiling.
    /// @param _priceEther Current price ETH/USD.
    /// @param _priceFactor Auction start price factor.
    /// @param _auctionPeriod Period of time when auction will be available after stop price is achieved in seconds.
    /// @param _auctionPrivateStart Index of block from which private auction should be started.
    /// @param _auctionPublicStart Index of block from which public auction should be started.
    /// @param _auctionClaimingStart Index of block from which claiming should be started.
    function PapyrusAuction(
        address _wallet,
        uint256 _ceiling,
        uint256 _priceEther,
        uint256 _priceFactor,
        uint256 _auctionPeriod,
        uint256 _auctionPrivateStart,
        uint256 _auctionPublicStart,
        uint256 _auctionClaimingStart
    ) {
        require(_wallet != address(0) && _ceiling != 0 && _priceEther != 0 && _priceFactor != 0 && _auctionPeriod != 0);
        require(_auctionPrivateStart <= _auctionPublicStart && _auctionPublicStart <= _auctionClaimingStart);
        require(_auctionPrivateStart > block.number);
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        auctionPeriod = _auctionPeriod;
        auctionPrivateStart = _auctionPrivateStart;
        auctionPublicStart = _auctionPublicStart;
        auctionClaimingStart = _auctionClaimingStart;
        stage = Stage.AuctionDeployed;
    }

    /// @dev Callback function just calls bid() function.
    function() public payable {
        bid(msg.sender);
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param _token Papyrus token address.
    /// @param _tokensToSell Amount of tokens expected to be sold during auction.
    /// @param _bonusPercent Percent of bonus tokens we share with private participants of the auction.
    /// @param _minPrivateBid Minimal amount of weis for private participants of the auction.
    /// @param _minPublicBid Minimal amount of weis for public participants of the auction.
    function setup(address _token, uint256 _tokensToSell, uint8 _bonusPercent, uint256 _minPrivateBid, uint256 _minPublicBid)
        public
        onlyOwner
        atStage(Stage.AuctionDeployed)
    {
        require(_token != address(0) && _tokensToSell != 0 && _minPrivateBid != 0 && _minPublicBid != 0);
        token = BasicToken(_token);
        tokensToSell = _tokensToSell;
        bonusPercent = _bonusPercent;
        minPrivateBid = _minPrivateBid;
        minPublicBid = _minPublicBid;
        require(token.balanceOf(this) >= tokensToSell);
        stage = Stage.AuctionSetUp;
    }

    /// @dev Changes auction ceiling and start price factor before auction is started.
    /// @param _ceiling Auction ceiling.
    /// @param _priceEther Current price ETH/USD.
    /// @param _priceFactor Auction start price factor.
    /// @param _auctionPeriod Period of time when auction will be available after stop price is achieved in seconds.
    /// @param _auctionPrivateStart Index of block from which private auction should be started.
    /// @param _auctionPublicStart Index of block from which public auction should be started.
    /// @param _auctionClaimingStart Index of block from which claiming should be started.
    function changeSettings(
        uint256 _ceiling,
        uint256 _priceEther,
        uint256 _priceFactor,
        uint256 _auctionPeriod,
        uint256 _auctionPrivateStart,
        uint256 _auctionPublicStart,
        uint256 _auctionClaimingStart
    )
        public
        onlyOwner
        atStage(Stage.AuctionSetUp)
    {
        require(_ceiling != 0 && _priceEther != 0 && _priceFactor != 0 && _auctionPeriod != 0);
        require(_auctionPrivateStart <= _auctionPublicStart && _auctionPublicStart <= _auctionClaimingStart);
        require(_auctionPrivateStart > block.number);
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        auctionPeriod = _auctionPeriod;
        auctionPrivateStart = _auctionPrivateStart;
        auctionPublicStart = _auctionPublicStart;
        auctionClaimingStart = _auctionClaimingStart;
    }

    /// @dev Allows specified address to participate in private stage of the auction.
    /// @param _participant Address of the participant of private stage of the auction.
    /// @param _amount Amount of weis allowed to bid for the participant.
    function allowPrivateParticipant(address _participant, uint256 _amount)
        public
        onlyOwner
        timedTransitions
    {
        require(_participant != address(0));
        require(stage == Stage.AuctionSetUp || stage == Stage.AuctionStartedPrivate);
        require(receivedBids[_participant] <= _amount);
        // _amount can be zero for cases when we want to disallow private participant
        privateParticipants[_participant] = _amount;
    }

    /// @dev Sets private auction start block index.
    function setPrivateAuctionStart(uint256 _blockIndex)
        public
        onlyOwner
        timedTransitions
        atStage(Stage.AuctionSetUp)
    {
        require(stage == Stage.AuctionSetUp);
        require(_blockIndex <= auctionPublicStart);
        auctionPrivateStart = _blockIndex;
    }

    /// @dev Sets public auction start block index.
    function setPublicAuctionStart(uint256 _blockIndex)
        public
        onlyOwner
        timedTransitions
    {
        require(stage == Stage.AuctionSetUp || stage == Stage.AuctionStartedPrivate);
        require(auctionPrivateStart <= _blockIndex && _blockIndex <= auctionClaimingStart);
        auctionPublicStart = _blockIndex;
    }

    /// @dev Sets tokens claiming start block index.
    function setClaimingStart(uint256 _blockIndex)
        public
        onlyOwner
        timedTransitions
    {
        require(stage >= Stage.AuctionSetUp && stage < Stage.ClaimingStarted);
        require(_blockIndex >= auctionPublicStart);
        auctionPublicStart = _blockIndex;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint256)
    {
        return stage >= Stage.AuctionFinishing ? finalPrice : calcTokenPrice();
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not been called yet.
    /// @return Returns current auction stage.
    function updateStage()
        public
        timedTransitions
        returns (Stage)
    {
        return stage;
    }

    /// @dev Allows to send a bid to the auction.
    /// @param receiver Bid will be assigned to this address if set.
    function bid(address receiver)
        public
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
        if (stage == Stage.AuctionStartedPrivate) {
            uint256 amountAllowed = privateParticipants[receiver];
            require(amountAllowed != 0 && amount >= minPrivateBid);
        } else if (stage >= Stage.AuctionStartedPublic && stage < Stage.AuctionFinished) {
            require(privateParticipants[receiver] == 0); // disallow bids from private participants addresses
        } else {
            revert();
        }
        amount = msg.value;
        // Prevent that more than specified amount of tokens are sold. Only relevant if cap not reached.
        uint256 maxWei = tokensToSell.div(E18).mul(calcTokenPrice()).sub(totalReceived);
        uint256 maxWeiBasedOnTotalReceived = ceiling.sub(totalReceived);
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;
        // Only invest maximum possible amount.
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
        if (receivedBids[receiver] == 0) {
            participants.push(receiver);
            ++participantCount;
        }
        receivedBids[receiver] = receivedBids[receiver].add(amount);
        if (stage == Stage.AuctionStartedPrivate) {
            privateReceived = privateReceived.add(amount);
        } else if (stage >= Stage.AuctionStartedPublic && stage < Stage.AuctionFinished) {
            publicReceived = publicReceived.add(amount);
        }
        totalReceived = totalReceived.add(amount);
        if (maxWei == amount) {
            // When maxWei is equal to the big amount the auction is ended and finalizeAuction is triggered.
            finalizeAuction();
        }
        BidSubmission(receiver, amount);
    }

    /// @dev Declines bid for specified bidder.
    /// @param bidder Address of bidder whose bid should be declined.
    function declineBid(address bidder)
        public
        onlyOwner
        timedTransitions
        atStage(Stage.AuctionFinished)
    {
        declinedBids[bidder] = receivedBids[bidder];
    }

    /// @dev Claims tokens/ether for bidder after auction.
    /// @param receiver Tokens/ether will be assigned to this address if set.
    function claim(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stage.ClaimingStarted)
    {
        if (receiver == address(0))
            receiver = msg.sender;
        require(receivedBids[receiver] > 0);
        bool bonusRequired = privateParticipants[receiver] > 0;
        uint256 declined = declinedBids[receiver];
        uint256 accepted = receivedBids[receiver].sub(declined);
        if (accepted > 0) {
            uint256 tokenCount = receivedBids[receiver].mul(E18).div(finalPrice);
            if (bonusRequired) {
                // TODO: Make sure here that all private participants get bonus tokens properly
            }
            // Forward funding to ether wallet
            if (!wallet.send(accepted)) {
                // Sending failed
                revert();
            }
            if (!token.transfer(receiver, tokenCount)) {
                // Sending failed
                revert();
            }
            acceptedBids[receiver] = acceptedBids[receiver].add(accepted);
        }
        if (declined > 0) {
            // Send change back to receiver address
            if (!receiver.send(declined)) {
                // Sending failed
                revert();
            }
            receivedBids[receiver] = receivedBids[receiver].sub(accepted);
        }
    }

    /// @dev Claims tokens/ether for bidders after auction.
    /// @param offset Starting index in array of bidders.
    /// @param limit Amount of bidders to perform claiming starting from offset.
    function claimAll(uint256 offset, uint256 limit)
        public
        isValidPayload
        timedTransitions
        atStage(Stage.ClaimingStarted)
        returns (uint256 claimed)
    {
        claimed = 0;
        for (uint256 i = offset; i < offset + limit && i < participants.length; ++i) {
            address participant = participants[i];
            if (receivedBids[participant] > 0 && receivedBids[participant] > acceptedBids[participant]) {
                claim(participant);
                ++claimed;
            }
        }
    }

    /// @dev Calculates stop price.
    /// @return Returns stop price.
    function calcStopPrice() constant public returns (uint256) {
        return totalReceived.mul(E18).div(tokensToSell).add(1);
    }

    /// @dev Calculates token price.
    /// @return Returns token price.
    function calcTokenPrice() constant public returns (uint256) {
        uint256 denominator = (stage >= Stage.AuctionStartedPublic ? block.number - auctionPublicStart : 0) + 7500;
        return priceFactor.mul(E18).div(denominator).add(1);
    }

    // PRIVATE FUNCTIONS

    function finalizeAuction() private {
        bool achieved = totalReceived == ceiling;
        stage = achieved ? Stage.AuctionFinished : Stage.AuctionFinishing;
        finalPrice = achieved ? calcTokenPrice() : calcStopPrice();
        uint256 tokensSold = totalReceived.mul(E18).div(finalPrice);
        if (tokensSold < tokensToSell) {
            // Auction contract transfers all unsold tokens to Papyrus inventory multisig
            token.transfer(wallet, tokensToSell.sub(tokensSold));
        }
        finishingTime = now;
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
        if (stage == Stage.AuctionSetUp && block.number >= auctionPrivateStart)
            stage = Stage.AuctionStartedPrivate;
        if (stage == Stage.AuctionStartedPrivate && block.number >= auctionPublicStart)
            stage = Stage.AuctionStartedPublic;
        if (stage == Stage.AuctionStartedPublic && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stage.AuctionFinishing && now > finishingTime + auctionPeriod)
            stage = Stage.AuctionFinished;
        if (stage == Stage.AuctionFinished && block.number >= auctionClaimingStart)
            stage = Stage.ClaimingStarted;
        _;
    }

    // FIELDS

    // Pre-Papyrus token should be sold during auction
    BasicToken public token;

    // Amount of tokens expected to be sold during whole auction
    uint256 public tokensToSell;

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

    // Auction price factor
    uint256 public priceFactor;

    // Period of time which auction will be available after stop price is achieved
    uint256 public auctionPeriod;

    // Index of block from which private auction should be started
    uint256 public auctionPrivateStart;

    // Index of block from which public auction should be started
    uint256 public auctionPublicStart;

    // Index of block from which claiming should be started
    uint256 public auctionClaimingStart;

    // Index of block from which auction was started
    uint256 public startBlock;

    // Timestamp when auction starting finishing (stop price achieved)
    uint256 public finishingTime;

    // Amount of received weis at private stage
    uint256 public privateReceived;

    // Amount of received weis at public stage
    uint256 public publicReceived;

    // Amount of total received weis
    uint256 public totalReceived;

    // Final token price used when auction is ended
    uint256 public finalPrice;

    // List of addresses of all participants of the auction
    // Needed to perform claimAll() function
    address[] public participants;
    
    // Count of all participants of the auction
    // Needed to perform claimAll() function
    uint256 public participantCount;

    // Addresses allowed to participate in private presale
    mapping (address => uint256) public privateParticipants;

    // Received bids
    mapping (address => uint256) public receivedBids;

    // Declined bids
    mapping (address => uint256) public declinedBids;

    // Accepted bids
    // Needed to perform claimAll() function
    mapping (address => uint256) public acceptedBids;

    // Current stage of the auction
    Stage public stage;

    // Some pre-calculated constant values
    uint256 private constant E18 = 10**18;
}
