// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NFTExchange} from "../src/NFTExchange.sol";
import {INFTExchange} from "../src/interfaces/INFTExchange.sol";
import {TestNFT} from "./utils/TestNFT.sol";
import {TestERC20} from "./utils/TestERC20.sol";
import {AirdropERC20} from "./utils/AirdropERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {BasicNFTFlashLoanReceiver} from "./utils/BasicNFTFlashLoanReceiver.sol";
import {MaliciousNFTFlashLoanReceiver} from "./utils/MaliciousNFTFlashLoanReceiver.sol";
import {ConnivingReceiver} from "./utils/ConnivingReceiver.sol";
import {AirdropClaimer} from "./utils/AirdropClaimer.sol";

contract NFTExchangeTest is Test, IERC721Receiver {
    NFTExchange public exchange;
    TestNFT public nft;
    TestERC20 public erc20;
    BasicNFTFlashLoanReceiver public flashLoanReceiver;
    MaliciousNFTFlashLoanReceiver public maliciousReceiver;
    ConnivingReceiver public connivingReceiver;
    AirdropERC20 public airdropToken;
    AirdropClaimer public airdropClaimer;
    INFTExchange.Listing public newListing;
    address public bob = vm.addr(1);
    uint256 public firstNFTId = 1;
    uint256 public firstListingId = 0;
    INFTExchange.Listing updatedListing = INFTExchange.Listing(
        true,
        address(this),
        true,
        address(erc20),
        0,
        address(nft),
        1,
        address(0),
        0,
        false,
        address(0),
        address(0),
        0,
        0
    );

    function setUp() public {
        exchange = new NFTExchange();
        nft = new TestNFT();
        erc20 = new TestERC20();
        flashLoanReceiver = new BasicNFTFlashLoanReceiver();
        maliciousReceiver = new MaliciousNFTFlashLoanReceiver(address(exchange));
        connivingReceiver = new ConnivingReceiver(address(exchange));
        airdropToken = new AirdropERC20(address(nft));
        airdropClaimer = new AirdropClaimer(address(nft), address(airdropToken));

        nft.mint(address(this), firstNFTId);
        newListing = INFTExchange.Listing(
            true,
            address(this),
            true,
            address(erc20),
            0,
            address(nft),
            firstNFTId,
            address(erc20),
            5e8,
            true,
            address(0),
            address(erc20),
            0,
            0
        );
        nft.approve(address(exchange), firstNFTId);
        vm.expectEmit(false, false, false, true);
        emit INFTExchange.ListingCreated(
            firstListingId,
            newListing.seller,
            newListing.asset,
            newListing.assetId,
            newListing.purchaseAsset,
            newListing.price,
            newListing.purchasable,
            newListing.loanAsset,
            newListing.loanFee,
            newListing.flashLoanable
        );
        exchange.createListing(newListing);
    }

    function testSetup() public view {
        assertEq(nft.balanceOf(address(exchange)), 1);
        assertEq(nft.ownerOf(1), address(exchange));
        assertEq(nft.balanceOf(address(this)), 0);
        assertTrue(checkListingsMatch(exchange.getListing(0), newListing));
    }

    function testCreateDuplicateListing() public {
        vm.expectRevert(INFTExchange.AlreadyListed.selector);
        exchange.createListing(newListing);
    }

    function testCreateListingAsOtherUser() public {
        nft.mint(address(this), 2);
        INFTExchange.Listing memory secondListing = INFTExchange.Listing(
            true, bob, true, address(0), 0, address(nft), 2, address(0), 0, false, address(0), address(0), 0, 0
        );
        nft.approve(address(exchange), 2);
        vm.expectRevert(INFTExchange.OnlyOwner.selector);
        exchange.createListing(secondListing);
    }

    function testUpdateListing() public {
        vm.expectEmit(false, false, false, true);
        emit INFTExchange.ListingUpdated(
            firstListingId,
            updatedListing.seller,
            updatedListing.asset,
            updatedListing.assetId,
            updatedListing.purchaseAsset,
            updatedListing.price,
            updatedListing.purchasable,
            updatedListing.loanAsset,
            updatedListing.loanFee,
            updatedListing.flashLoanable
        );
        exchange.updateListing(0, updatedListing);
    }

    function testUpdateListingToInactive() public {
        updatedListing.active = false;

        vm.expectRevert(INFTExchange.InvalidOperation.selector);
        exchange.updateListing(0, updatedListing);
    }

    function testNonOwnerUpdateListing() public {
        vm.startPrank(bob);
        vm.expectRevert(INFTExchange.OnlyOwner.selector);
        exchange.updateListing(0, updatedListing);
        vm.stopPrank();
    }

    function testUpdateInactiveListing() public {
        exchange.cancelListing(0);
        vm.expectRevert(INFTExchange.InactiveListing.selector);
        exchange.updateListing(0, updatedListing);
        vm.stopPrank();
    }

    function testCancelListing() public {
        vm.expectEmit(false, false, false, true);
        emit INFTExchange.ListingCancelled(0, address(this), address(nft), 1);
        exchange.cancelListing(0);
    }

    function testDoubleCancelListing() public {
        vm.expectEmit(false, false, false, true);
        emit INFTExchange.ListingCancelled(0, address(this), address(nft), 1);
        exchange.cancelListing(0);

        vm.expectRevert(INFTExchange.InactiveListing.selector);
        exchange.cancelListing(0);
    }

    function testCancelListingNonOwner() public {
        vm.startPrank(bob);
        vm.expectRevert(INFTExchange.OnlyOwner.selector);
        exchange.cancelListing(0);
        vm.stopPrank();
    }

    function testPurchaseListing() public {
        vm.startPrank(bob);
        erc20.mint(bob, 5e8);
        erc20.approve(address(exchange), 5e8);
        vm.expectEmit(false, false, false, true);
        emit INFTExchange.ListingPurchased(
            firstListingId, newListing.seller, bob, newListing.asset, newListing.assetId, newListing.price
        );
        exchange.purchaseListing(firstListingId);
        assertEq(nft.ownerOf(1), bob);
        assertEq(erc20.balanceOf(address(this)), 5e8);
        assertEq(erc20.balanceOf(bob), 0);
        vm.stopPrank();
    }

    function testPurchaseTwice() public {
        vm.startPrank(bob);
        erc20.mint(bob, 10e8);
        erc20.approve(address(exchange), 10e8);
        exchange.purchaseListing(firstListingId);
        vm.expectRevert(INFTExchange.InactiveListing.selector);
        exchange.purchaseListing(firstListingId);
        vm.stopPrank();
    }

    function testPurchaseNonPurchasableListing() public {
        newListing.purchasable = false;
        exchange.updateListing(firstListingId, newListing);
        vm.startPrank(bob);
        erc20.mint(bob, 5e8);
        erc20.approve(address(exchange), 5e8);
        vm.expectRevert(INFTExchange.NotPurchasable.selector);
        exchange.purchaseListing(firstListingId);
        vm.stopPrank();
    }

    function testCreateBid() public {
        vm.startPrank(bob);
        erc20.mint(bob, 5e8);
        erc20.approve(address(exchange), 5e8);
        vm.expectEmit(false, false, false, true);
        emit INFTExchange.BidCreated(firstListingId, bob, newListing.bidAsset, 5e8, block.timestamp);
        exchange.createBid(firstListingId, 5e8);
        assertEq(erc20.balanceOf(address(exchange)), 5e8);
        assertEq(erc20.balanceOf(bob), 0);
        vm.stopPrank();
    }

    function testCancelBid() public {
        vm.startPrank(bob);
        erc20.mint(bob, 5e8);
        erc20.approve(address(exchange), 5e8);
        vm.expectEmit(false, false, false, true);
        emit INFTExchange.BidCreated(firstListingId, bob, newListing.bidAsset, 5e8, block.timestamp);
        exchange.createBid(firstListingId, 5e8);
        assertEq(erc20.balanceOf(address(exchange)), 5e8);
        assertEq(erc20.balanceOf(bob), 0);

        vm.expectEmit(false, false, false, true);
        emit INFTExchange.BidCancelled(firstListingId, bob, newListing.bidAsset, 5e8, block.timestamp);
        exchange.cancelBid(firstListingId);
        assertEq(erc20.balanceOf(address(exchange)), 0);
        assertEq(erc20.balanceOf(bob), 5e8);
        vm.stopPrank();
    }

    function testAcceptBid() public {
        vm.startPrank(bob);
        erc20.mint(bob, 5e8);
        erc20.approve(address(exchange), 5e8);
        exchange.createBid(firstListingId, 5e8);
        vm.stopPrank();

        vm.expectEmit(false, false, false, true);
        emit INFTExchange.BidAccepted(firstListingId, bob, newListing.bidAsset, 5e8, block.timestamp);
        exchange.acceptBid(firstListingId);
        assertEq(nft.ownerOf(1), bob);
        assertEq(erc20.balanceOf(address(exchange)), 0);
        assertEq(erc20.balanceOf(bob), 0);
        assertEq(erc20.balanceOf((address(this))), 5e8);
    }

    /*
     * We test a bid replay attack. Bob was the highest bidder and won an NFT. Now he lists again, and the previous owner 
     * tries to accept the old bid. This should fail because that auction has closed.
     */
    function testReplayBid() public {
        vm.startPrank(bob);
        erc20.mint(bob, 5e8);
        erc20.approve(address(exchange), 5e8);
        exchange.createBid(firstListingId, 5e8);
        vm.stopPrank();

        exchange.acceptBid(firstListingId);
        assertEq(nft.ownerOf(1), bob);
        assertEq(erc20.balanceOf(address(exchange)), 0);
        assertEq(erc20.balanceOf(bob), 0);
        assertEq(erc20.balanceOf((address(this))), 5e8);

        vm.startPrank(bob);
        nft.approve(address(exchange), 1);
        INFTExchange.Listing memory bobListing = INFTExchange.Listing(
            true,
            bob,
            true,
            address(erc20),
            0,
            address(nft),
            firstNFTId,
            address(erc20),
            20e8,
            true,
            address(0),
            address(erc20),
            0,
            0
        );
        exchange.createListing(bobListing);
        vm.stopPrank();

        assertTrue(checkListingsMatch(exchange.getListing(1), bobListing));

        vm.expectRevert(INFTExchange.InactiveListing.selector);
        exchange.acceptBid(firstListingId);
    }

    /*
     * Basic flashloan test. User flashloans a listed NFT, checks that their contract holds the NFT inside the call, 
     * and then returns the NFT (no fee)
     */
    function testBasicFlashLoan() public {
        assertEq(nft.ownerOf(1), address(exchange));
        assertEq(nft.balanceOf(address(this)), 0);
        assertEq(nft.balanceOf(address(flashLoanReceiver)), 0);

        exchange.flashLoanNFT(0, address(flashLoanReceiver));
        assertEq(nft.ownerOf(1), address(exchange));
        assertEq(nft.balanceOf(address(flashLoanReceiver)), 0);
    }

    /*
     * User flashloans an NFT, and claims an airdrop ERC20 token reward.
     * User pays most of the claimed rewards back to the NFT seller as a fee, keeping the rest
     */
    function testClaimAirdropWithFlashloan() public {
        nft.mint(address(this), 2);
        newListing = INFTExchange.Listing(
            true,
            address(this),
            true,
            address(airdropToken),
            800e18,
            address(nft),
            2,
            address(0),
            0,
            false,
            address(0),
            address(0),
            0,
            0
        );
        nft.approve(address(exchange), 2);
        exchange.createListing(newListing);
        assertEq(nft.ownerOf(2), address(exchange));
        assertEq(nft.balanceOf(address(this)), 0);

        exchange.flashLoanNFT(1, address(airdropClaimer));
        assertEq(nft.ownerOf(2), address(exchange));
        assertEq(nft.balanceOf(address(airdropClaimer)), 0);

        assertEq(airdropToken.balanceOf(address(this)), 800e18);
        assertEq(airdropToken.balanceOf(address(airdropClaimer)), 200e18);
        assertEq(airdropToken.balanceOf(address(exchange)), 0);
    }

    /*
     * Malicious user tries to flashloan NFT and create their own listing. This is so they can either try and buy
     * the NFT for cheap, or cancel their listing to receive the NFT, which is the default behavior for listing
     * cancellations
     * 
     * This fails because the contract checks if there already is an active listing for each NFT 
     */
    function testCreateDuplicateListingViaFlashLoan() public {
        assertEq(nft.ownerOf(1), address(exchange));
        assertEq(nft.balanceOf(address(this)), 0);
        assertEq(nft.balanceOf(address(flashLoanReceiver)), 0);

        vm.expectRevert(INFTExchange.AlreadyListed.selector);
        exchange.flashLoanNFT(0, address(maliciousReceiver));
    }

    /*
     * Malicious user tries to flash loan NFT and upate the current listing. Should fail because they are not the
     * original seller.
     */
    function testUpdateListingViaFlashLoan() public {
        assertEq(nft.ownerOf(1), address(exchange));
        assertEq(nft.balanceOf(address(this)), 0);
        assertEq(nft.balanceOf(address(flashLoanReceiver)), 0);

        vm.expectRevert(INFTExchange.OnlyOwner.selector);
        exchange.flashLoanNFT(0, address(connivingReceiver));
    }

    function checkListingsMatch(INFTExchange.Listing memory firstListing, INFTExchange.Listing memory secondListing)
        public
        pure
        returns (bool)
    {
        if (firstListing.active != secondListing.active) {
            return false;
        }
        if (firstListing.seller != secondListing.seller) {
            return false;
        }
        if (firstListing.flashLoanable != secondListing.flashLoanable) {
            return false;
        }
        if (firstListing.loanAsset != secondListing.loanAsset) {
            return false;
        }
        if (firstListing.loanFee != secondListing.loanFee) {
            return false;
        }
        if (firstListing.asset != secondListing.asset) {
            return false;
        }
        if (firstListing.assetId != secondListing.assetId) {
            return false;
        }
        if (firstListing.purchaseAsset != secondListing.purchaseAsset) {
            return false;
        }
        if (firstListing.price != secondListing.price) {
            return false;
        }
        if (firstListing.purchasable != secondListing.purchasable) {
            return false;
        }
        if (firstListing.highestBidder != secondListing.highestBidder) {
            return false;
        }
        if (firstListing.bidAsset != secondListing.bidAsset) {
            return false;
        }
        if (firstListing.highestBid != secondListing.highestBid) {
            return false;
        }
        if (firstListing.bidTime != secondListing.bidTime) {
            return false;
        }

        return true;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
