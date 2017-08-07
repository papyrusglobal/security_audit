pragma solidity ^0.4.11;

import "./PapyrusAuction.sol";
import "./PrePapyrusToken.sol";

/// @title Papyrus sale phase 1 auction contract - distribution of Papyrus tokens using an auction.
contract PapyrusSalePhase1 is PapyrusAuction {

    // PUBLIC FUNCTIONS

    /// @dev Contract constructor function.
    /// @param _presaleAuction PapyrusPresale contract address.
    /// @param _wallet Papyrus multisig wallet address for storing ETH after claiming.
    /// @param _ceiling Auction ceiling.
    /// @param _priceEther Current price ETH/USD.
    /// @param _priceFactor Auction start price factor.
    /// @param _auctionPeriod Period of time when auction will be available after stop price is achieved in seconds.
    /// @param _auctionPrivateStart Index of block from which private auction should be started.
    /// @param _auctionPublicStart Index of block from which public auction should be started.
    /// @param _auctionClaimingStart Index of block from which claiming should be started.
    function PapyrusSalePhase1(
        address _presaleAuction,
        address _wallet,
        uint256 _ceiling,
        uint256 _priceEther,
        uint256 _priceFactor,
        uint256 _auctionPeriod,
        uint256 _auctionPrivateStart,
        uint256 _auctionPublicStart,
        uint256 _auctionClaimingStart
    )
        PapyrusAuction(_wallet, _ceiling, _priceEther, _priceFactor, _auctionPeriod, _auctionPrivateStart, _auctionPublicStart, _auctionClaimingStart)
    {
        require(_presaleAuction != address(0));
        presaleAuction = PapyrusAuction(presaleAuction);
    }

    /// @dev Claims tokens/ether for bidder after auction.
    /// @param receiver Tokens/ether will be assigned to this address if set.
    function claim(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stage.ClaimingStarted)
    {
        // TODO: Override so it calculates tokens claiming and exchanging based on result of pre-sale auction
        super.claim(receiver);
    }

    /// @dev Exchanges PRP tokens to PPR tokens.
    /// @param receiver PPR will be assigned to this address if set.
    function exchange(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stage.ClaimingStarted)
    {
        if (receiver == address(0))
            receiver = msg.sender;
        uint256 receiverBalance = presaleAuction.token().balanceOf(receiver);
        require(receiverBalance > 0);
        // TODO: Make sure exchange is done using all necessary bonuses for pre-sale participation
        uint256 tokenCount = receiverBalance;
        if (!token.transfer(receiver, tokenCount)) {
            // Sending failed
            revert();
        }
        PrePapyrusToken prePapyrusToken = PrePapyrusToken(presaleAuction.token());
        prePapyrusToken.burn(receiver, receiverBalance);
    }

    /// @dev Exchanges PRP tokens to PPR tokens.
    /// @param offset Starting index in array of pre-sale bidders.
    /// @param limit Amount of pre-sale bidders to perform exchanging starting from offset.
    function exchangeAll(uint256 offset, uint256 limit)
        public
        isValidPayload
        timedTransitions
        atStage(Stage.ClaimingStarted)
        returns (uint256 exchanged)
    {
        exchanged = 0;
        for (uint256 i = offset; i < offset + limit && i < presaleAuction.participantCount(); ++i) {
            address participant = presaleAuction.participants(i);
            uint256 participantBalance = presaleAuction.token().balanceOf(participant);
            if (participantBalance > 0) {
                exchange(participant);
                ++exchanged;
            }
        }
    }

    // FIELDS

    PapyrusAuction public presaleAuction;
}
