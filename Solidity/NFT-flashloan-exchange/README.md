# NFT Flash Loan Exchange

This repository contains a set of smart contracts implementing a basic NFT exchange. Additionally, the exchange allows for flashloans of NFTs. Users can specify whether their listed NFT can be bought and/or flashloaned.

## Motivation

Flashloans typically involve borrowing one or many ERC20 assets from a pool and returning them with a fee. In some cases they have been used to [borrow NFTs](https://www.theblock.co/post/138410/someone-borrowed-5-bored-apes-to-claim-1-1-million-of-ape-tokens).  

Allowing users to directly flashloan NFTs offers some benefits:  

**1. Convenient Yield For Passive NFT Investors**  
 Keeping up-to-date with Twitter feeds, Discord announcements, Medium articles and more can be quite tedious for investors who prefer to hold their NFTs passively. The tedium scales with the number of different projects held. Instead, with flashloans, holders can specify reward amounts and have other, more dedicated users implement flashloans to retrieve and share the reward.

 **2. Reduced Risk**  
 The NFT space is rife with [airdrop scams](https://www.chainabuse.com/category/airdrop), where malicious users craft a seemingly benign and legitimate website that promises an airdrop reward for holding an NFT. However, these scam websites will often drain wallets, leading to [catastrophic losses](https://www.tripwire.com/state-of-security/cryptocurrency-wallet-ceo-loses-125000-wallet-draining-scam). Flashloans can help to avoid the inconvenience and risk of self-auditing websites before connecting one's wallet for a claim.

 **3. Shared Rewards**  
 Many airdrop rewards currently go [unclaimed](https://www.thecoinrepublic.com/2023/03/16/3500-yuga-labs-sewer-pass-nfts-remain-unclaimed-for-summoning/). NFT flashloans are mutually beneficial for passive investors and active developers because they help share the rewards that are otherwise lost to market inefficiencies.

## Related Work

There is currently an open [draft EIP](https://eips.ethereum.org/EIPS/eip-6682) discussing a minimal interface for ERC-721 NFT flashloans, the flavor implemented in this repository.  

Additionally, [Very Nifty](https://medium.com/nft20/introducing-nft-flash-loans-97ff8c9298d4) has shown the idea as well.

## Design Decisions

The contract is intended to be as decentralized and transparent as possible. For this reason, all the assets to be traded are at the sole discretion of users. There is no owner, or any parameters set in the constructor, meaning there is no central influence on the behaviors of this marketplace. Furthermore, the contract is not upgradeable, so the code will deploy and stay forever as is. Not even the deployer can change the code.  

The marketplace uses fully collateralized bids with the scheme that only the highest bid is stored. Furthermore, bids, once placed, may not be cancelled until 7 days following. The purpose of this is to avoid a few non-ideal scenarios, and make the logic work fully on-chain:  

**1. Fake Bids**  
If the highest bidder is unable to pay the bid at the time the bid is selected, they are essentially DDOS'ing the auction, and wasting the seller's gas. Fully collateralized bids ensures the integrity of the highest bid.

**2. Bid Griefing**  
The purpose of the 7 day non-cancellation period is to avoid the situation where a user proposes a valid, fully collateralized highest bid, but them immediately cancels their bid, effectively voiding the previous highest bidder's bid.

**3. Out-Of-Gas Issues**  
If any address was allowed to place a bid, storing all bids on-chain would get prohibitively expensive, up to the point that transactions would fail due to being out-of-gas. Maintaining just the highest bid avoids this problem and reduces the cost and space requirements.  

Naturally, these design decisions come with their tradeoffs. Notably, a 7 day non-cancellation period can be prohibitive for high-frequency traders. Feedback to this design is highly encouraged, and can be submitted to cheyenneatapour@gmail.com.

## Significant Examples

Please see the tests within [the test suite](test/NFTExchange.t.sol) to see demonstrations of NFT flashloans.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Deploy

```shell
$ forge script script/NFTExchange.s.sol:NFTExchangeScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```
