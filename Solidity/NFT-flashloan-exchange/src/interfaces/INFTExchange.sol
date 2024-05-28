// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title INFTExchange
 * @author Cheyenne Atapour
 * @notice Defines the basic interface for the NFT Exchange
 */
interface INFTExchange {
    error OnlyOwner();
    error OnlyBidder();
    error AlreadyListed();
    error NotPurchasable();
    error NotFlashLoanable();
    error InvalidAmount();
    error InactiveListing();
    error UnreturnedLoan();
    error InsufficientLoanFee();
    error InsufficientBid();
    error MinimumTimeUnmet();
    error InvalidOperation();

    struct Listing {
        bool active;
        address seller;
        bool flashLoanable;
        address loanAsset;
        uint256 loanFee;
        address asset;
        uint256 assetId;
        address purchaseAsset;
        uint256 price;
        bool purchasable;
        address highestBidder;
        address bidAsset;
        uint256 highestBid;
        uint256 bidTime;
    }

    event ListingCreated(
        uint256 listingIndex,
        address seller,
        address asset,
        uint256 assetId,
        address purchaseAsset,
        uint256 price,
        bool purchasable,
        address loanAsset,
        uint256 loanFee,
        bool flashLoanable
    );
    event ListingUpdated(
        uint256 listingIndex,
        address seller,
        address asset,
        uint256 assetId,
        address purchaseAsset,
        uint256 price,
        bool purchasable,
        address loanAsset,
        uint256 loanFee,
        bool flashLoanable
    );
    event ListingCancelled(uint256 listingIndex, address seller, address asset, uint256 assetId);
    event ListingPurchased(
        uint256 listingIndex, address seller, address buyer, address asset, uint256 assetId, uint256 price
    );
    event BidCreated(
        uint256 listingIndex, address highestBidder, address bidAsset, uint256 highestBid, uint256 bidTime
    );
    event BidCancelled(
        uint256 listingIndex,
        address previousBidder,
        address bidAsset,
        uint256 previousHighestBid,
        uint256 cancellationTime
    );
    event BidAccepted(
        uint256 listingIndex, address highestBidder, address bidAsset, uint256 highestBid, uint256 transactionTime
    );
    event FlashLoanedNFT(
        uint256 listingIndex, address asset, uint256 assetId, address loanAsset, uint256 loanFee, address borrower
    );

    /**
     * @notice Creates a new NFT listing, specifying sale and/or FlashLoan details
     * @param newListing The new listing
     * @dev msg.sender must own the NFT and match Listing.seller
     */
    function createListing(Listing calldata newListing) external;

    /**
     * @notice Updates an existing NFT listing
     * @param listingIndex The index of the listing to update
     * @param updatedListing The updated listing
     * @dev Disallow cancelling listing to avoid unintentional NFT locking
     */
    function updateListing(uint256 listingIndex, Listing calldata updatedListing) external;

    /**
     * @notice Cancels an existing NFT listing, returning NFT to original owner
     * @param listingIndex The index of the listing to cancel
     */
    function cancelListing(uint256 listingIndex) external;

    /**
     * @notice Purchase an NFT listing
     * @param listingIndex The index of the listing to purchase
     * @dev Address(0) signifies ETH purchase asset
     * @dev Listing must be active and purchasable
     */
    function purchaseListing(uint256 listingIndex) external payable;

    /**
     * @notice Create a new bid for an NFT listing
     * @param listingIndex The index of the listing to place bid on
     * @param bidAmount The amount of the bid
     * @dev Bid is fully collateralized; assets transferred within call
     * @dev Only stores highest bid, refunding previous bidder
     * @dev Bid asset was set during listing creation
     */
    function createBid(uint256 listingIndex, uint256 bidAmount) external;

    /**
     * @notice Cancels existing bid, returning funds to original bidder
     * @param listingIndex The index of the listing to cancel bid
     * @dev Enforces 7 day minimum bid time to prevent grief attacks
     * @dev Resets highest bidder
     */
    function cancelBid(uint256 listingIndex) external;

    /**
     * @notice Accepts the highest bid on specified NFT listing
     * @param listingIndex The index of the listing to accept bid on
     * @dev Resets highest bid to prevent replay attacks
     */
    function acceptBid(uint256 listingIndex) external;

    /**
     * @notice FlashLoan an NFT listing
     * @param listingIndex The NFT listing to flash loan
     * @param receiver The receving contract of the flash loan (borrower)
     * @dev Receiving contract must implement onERC721Received and executeOperation functions
     */
    function flashLoanNFT(uint256 listingIndex, address receiver) external;
}
