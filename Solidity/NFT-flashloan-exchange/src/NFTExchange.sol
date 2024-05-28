// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INFTExchange} from "./interfaces/INFTExchange.sol";
import {INFTFlashLoanReceiver} from "./interfaces/INFTFlashLoanReceiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title NFTExchange contract
 * @author Cheyenne Atapour
 * @notice Main point of interaction with the FlashLoan NFT marketplace
 * - Users can:
 *   # List their NFTs for sale and/or FlashLoans
 *   # Purchase NFTs
 *   # Update their NFT listings
 *   # Bid on NFTs
 */
contract NFTExchange is INFTExchange, IERC721Receiver {
    Listing[] public listings;
    mapping(address => mapping(uint256 => bool)) public alreadyListed;

    function getListing(uint256 listingIndex) public view returns (Listing memory) {
        return listings[listingIndex];
    }

    /// @inheritdoc INFTExchange
    function createListing(Listing calldata newListing) external {
        _validateNewListing(newListing);

        _storeNewListing(newListing);

        emit ListingCreated(
            listings.length - 1,
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
    }

    /// @inheritdoc INFTExchange
    function updateListing(uint256 listingIndex, Listing calldata updatedListing) external {
        _validateUpdatedListing(listingIndex, updatedListing);

        listings[listingIndex] = updatedListing;

        emit ListingUpdated(
            listingIndex,
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
    }

    /// @inheritdoc INFTExchange
    function cancelListing(uint256 listingIndex) external {
        _validateCancelListing(listingIndex);
        Listing memory listing = getListing(listingIndex);

        IERC721(listing.asset).safeTransferFrom(address(this), msg.sender, listing.assetId, "");

        listings[listingIndex].active = false;
        alreadyListed[listing.asset][listing.assetId] = false;

        emit ListingCancelled(listingIndex, msg.sender, listing.asset, listing.assetId);
    }

    /// @inheritdoc INFTExchange
    function purchaseListing(uint256 listingIndex) external payable {
        Listing memory listing = getListing(listingIndex);
        _validatePurchaseListing(listing);

        _purchaseListing(listing);

        _updatePurchasedListing(listingIndex, listing);

        emit ListingPurchased(listingIndex, listing.seller, msg.sender, listing.asset, listing.assetId, listing.price);
    }

    /// @inheritdoc INFTExchange
    function createBid(uint256 listingIndex, uint256 bidAmount) external {
        Listing memory listing = getListing(listingIndex);

        _validateNewBid(listing, bidAmount);

        if (listing.highestBidder != address(0)) {
            SafeERC20.safeTransferFrom(
                IERC20(listing.bidAsset), address(this), listing.highestBidder, listing.highestBid
            );
        }
        SafeERC20.safeTransferFrom(IERC20(listing.bidAsset), msg.sender, address(this), bidAmount);

        listings[listingIndex].highestBidder = msg.sender;
        listings[listingIndex].highestBid = bidAmount;
        listings[listingIndex].bidTime = block.timestamp;

        emit BidCreated(listingIndex, msg.sender, listing.bidAsset, bidAmount, block.timestamp);
    }

    /// @inheritdoc INFTExchange
    function cancelBid(uint256 listingIndex) external {
        Listing memory listing = getListing(listingIndex);

        _validateCancelBid(listing);

        SafeERC20.safeTransfer(IERC20(listing.bidAsset), listing.highestBidder, listing.highestBid);

        emit BidCancelled(listingIndex, msg.sender, listing.bidAsset, listing.highestBid, block.timestamp);

        listings[listingIndex].highestBidder = address(0);
        listings[listingIndex].highestBid = 0;
        listings[listingIndex].bidTime = 0;
    }

    /// @inheritdoc INFTExchange
    function acceptBid(uint256 listingIndex) external {
        Listing memory listing = getListing(listingIndex);

        _validateAcceptBid(listing);

        SafeERC20.safeTransfer(IERC20(listing.bidAsset), listing.seller, listing.highestBid);

        IERC721(listing.asset).safeTransferFrom(address(this), listing.highestBidder, listing.assetId, "");

        emit BidAccepted(listingIndex, listing.highestBidder, listing.bidAsset, listing.highestBid, block.timestamp);

        listings[listingIndex].highestBidder = address(0);
        listings[listingIndex].highestBid = 0;
        listings[listingIndex].bidTime = 0;
        listings[listingIndex].active = false;
        alreadyListed[listing.asset][listing.assetId] = false;
    }

    /// @inheritdoc INFTExchange
    function flashLoanNFT(uint256 listingIndex, address receiver) external {
        Listing memory listing = getListing(listingIndex);
        uint256 previousFeeBalance = IERC20(listing.loanAsset).balanceOf(address(this));

        _validateFlashLoan(listing);

        IERC721(listing.asset).safeTransferFrom(address(this), receiver, listing.assetId, "");
        INFTFlashLoanReceiver(receiver).executeOperation(
            listing.asset, listing.assetId, listing.loanAsset, listing.loanFee
        );

        _validateReturnedLoan(listing, previousFeeBalance);

        IERC20(listing.loanAsset).approve(address(listing.seller), listing.loanFee);
        SafeERC20.safeTransfer(IERC20(listing.loanAsset), listing.seller, listing.loanFee);

        emit FlashLoanedNFT(
            listingIndex, listing.asset, listing.assetId, listing.loanAsset, listing.loanFee, msg.sender
        );
    }

    function _validateNewListing(Listing calldata newListing) internal view {
        if (newListing.seller != msg.sender) {
            revert OnlyOwner();
        }
        if (alreadyListed[newListing.asset][newListing.assetId]) {
            revert AlreadyListed();
        }
    }

    function _storeNewListing(Listing calldata newListing) internal {
        IERC721(newListing.asset).safeTransferFrom(msg.sender, address(this), newListing.assetId, "");
        listings.push(newListing);
        alreadyListed[newListing.asset][newListing.assetId] = true;
    }

    function _validateUpdatedListing(uint256 listingIndex, Listing calldata updatedListing) internal view {
        if (!listings[listingIndex].active) {
            revert InactiveListing();
        }
        if (listings[listingIndex].seller != msg.sender) {
            revert OnlyOwner();
        }
        if (!updatedListing.active) {
            revert InvalidOperation();
        }
    }

    function _validateCancelListing(uint256 listingIndex) internal view {
        if (!listings[listingIndex].active) {
            revert InactiveListing();
        }
        if (listings[listingIndex].seller != msg.sender) {
            revert OnlyOwner();
        }
    }

    function _validatePurchaseListing(Listing memory listing) internal pure {
        if (!listing.active) {
            revert InactiveListing();
        }
        if (!listing.purchasable) {
            revert NotPurchasable();
        }
    }

    function _purchaseListing(Listing memory listing) internal {
        if (listing.purchaseAsset == address(0)) {
            if (msg.value != listing.price) {
                revert InvalidAmount();
            }
        } else {
            SafeERC20.safeTransferFrom(IERC20(listing.purchaseAsset), msg.sender, listing.seller, listing.price);
        }
        IERC721(listing.asset).safeTransferFrom(address(this), msg.sender, listing.assetId, "");
    }

    function _updatePurchasedListing(uint256 listingIndex, Listing memory listing) internal {
        alreadyListed[listing.asset][listing.assetId] = false;
        listing.active = false;
        listing.highestBidder = address(0);
        listing.highestBid = 0;
        listing.bidTime = 0;

        listings[listingIndex] = listing;
    }

    function _validateNewBid(Listing memory listing, uint256 bidAmount) internal pure {
        if (!listing.active) {
            revert InactiveListing();
        }
        if (!listing.purchasable) {
            revert NotPurchasable();
        }

        if (listing.highestBid >= bidAmount) {
            revert InsufficientBid();
        }
    }

    function _validateCancelBid(Listing memory listing) internal view {
        if (!listing.active) {
            revert InactiveListing();
        }
        if (listing.highestBidder != msg.sender) {
            revert OnlyBidder();
        }
    }

    function _validateAcceptBid(Listing memory listing) internal view {
        if (!listing.active) {
            revert InactiveListing();
        }
        if (msg.sender != listing.seller) {
            revert OnlyOwner();
        }
    }

    function _validateFlashLoan(Listing memory listing) internal pure {
        if (!listing.active) {
            revert InactiveListing();
        }
        if (!listing.flashLoanable) {
            revert NotFlashLoanable();
        }
    }

    function _validateReturnedLoan(Listing memory listing, uint256 previousFeeBalance) internal view {
        if (IERC721(listing.asset).ownerOf(listing.assetId) != address(this)) {
            revert UnreturnedLoan();
        }
        if (IERC20(listing.loanAsset).balanceOf(address(this)) != previousFeeBalance + listing.loanFee) {
            revert InsufficientLoanFee();
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
