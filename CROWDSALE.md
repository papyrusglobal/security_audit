# Papyrus Token Generation Event

We are planning to use a milestone-based approach for the upcoming TGEs:

- **TGE Round 1**: Launch on October 2017 after Papyrus prototype with initial scope in Ethereum network will be deployed.

- **TGE Round 2**: Launch date to be announced. TGE Round 2 will be launched after Papyrus successfully accomplish pilot integrations with external advertising platforms and partners proving benefits of Papyrus on real use cases and deploy initial production release of the ecosystem for testing. According to the plan it will happen in next few months.

- **TGE Round 3**: Tokens allocated for this event will be locked until 2019. TGE Round 3 will be launched not earlier than in 2019 after achieving significant market traction of Papyrus, growing user base and ad traffic volume handled within the ecosystem.

Papyrus is introducing two different tokens:

- **PRP** tokens with utility in Papyrus ecosystem prototype. This tokens will be generated during **TGE Round 1** and used to bootstrap Papyrus prototype and start pilot integrations.

- **PPR** tokens with utility in production Papyrus ecosystem. This token will be generated during **TGE Round 2** and will be main tokens of Papyrus economy during its long-term development and adoption on advertising market.

**PRP** tokens will be exchanged to **PPR** tokens after **TGE Round 2** as described below.

## PRP tokens

**PRP** tokens will be issued during **TGE Round 1** and will be immediately applicable in the initial prototype of the Papyrus ecosystem. If target hard cap is reached the number of **PRP** tokens will be fixed and the end of the **TGE Round 1** and no additional creation will be allowed. Otherwise additional TGE round for **PPR** tokens may be scheduled to reach target hard cap. After hard cap is reached as a cumulative result of these TGEs the amount of **PRP** tokens will be fixed and no **PRP** token creation will be allowed.

The **PRP** token allocation will have the following configuration:

- **80%** will be sold during **TGE Round 1**;
- **20%** will be allocated for advisory board, bounty campaign, Papyrus partners, pilot integrations with ad platforms, and founding team.

## PPR tokens

Papyrus plan to suspend support of prototype ecosystem and continue development of production ecosystem only after **TGE Round 2** is finished and exchange of **PRP** tokens to **PPR** tokens is opened.

## TGE Round 1 structure

Papyrus TGE Round 1 hard cap is **$5,000,000**. Any funds on top of that will be transmitted back at the cost of the contributor. The company can choose a lower hard cap if deems it reasonable.

TGE Round 1 will start on October 2017 and will end when any one of the following ending criterion are met:
- Hard cap is reached;
- Designated TGE Round 1 period of **14 days** ends.

PRP price is nominated in **USD** and specified as follows:
- **During first 2 hours** of the TGE Round 1 period PRP price will be **$0.80**;
- **From 3rd to 24th hour** (both including) of the TGE Round 1 period PRP price will be **$0.90**;
- **From 2nd to 7th day** (both including) of the TGE Round 1 period PRP price will be **$0.95**;
- **After 7th day** and until the end of the TGE Round 1 period PRP price will be **$1.00**.

Payments for the tokens will be accepted in **ETH** and **BTC** using established conversion ratio to **USD**.

The TGE Round 1 will be compliant with international anti-money laundering (AML) requirements and may require participants to undergo KYC (know your customer) checks. Details about AML policy will be published soon.

Parties interested in buying PRP tokens for amounts of **>=$50,000** can participate in pre order of PRP tokens with special discounted token price. Pre order has maximum cap of **$2,500,000**. All interested parties can already submit requests for participation in the pre order via the Papyrus official website.

### Technical view

Here is short information about how **TGE Round 1** will be organized technically.

#### Dedicated server

On dedicated server we have set up and run nodes for Bitcoin and Ethereum networks. This server constantly monitors both **TGE Round 1** wallets (BTC and ETH) and counts all received BTC or ETH. Following data is counted for each received transaction:
- Address from which ETH received or address which was used for BTC transfer.
- Amount of received BTC or ETH.
- Timestamp of transaction (block of transaction) - using this we can calculate token price properly.

Since final price of PRP token depends on **BTC/USD and ETH/USD prices**, dedicated server also counts that prices constantly. Server does not use any external API to grab BTC/USD and ETH/USD prices automatically. Papyrus team will update that prices on dedicated server manually once per day. This way there is additional data for each received transaction - BTC/USD or ETH/USD price at moment of transaction.

Each participant of **TGE Round 1** will be **KYC verified** before any tokens are transferred to him/her. Participants who are not KYC verified will get their BTC and ETH back instead of PRP tokens.

When **TGE Round 1** and all KYC verifications are finished Papyrus team will mint necessary amount of PRP tokens for all participants. Non-accepted BTC/ETH are also returned back if necessary.

To do transfering PRP tokens possible it is necessary to set PRP token transferable (using function `setTransferable()` with argument `true` from *owner* address).

## TGE Round 2 structure

To be announced later.

## TGE Round 3 structure

To be announced later.
