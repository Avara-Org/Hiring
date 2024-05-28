// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INFTFlashLoanReceiver} from "../../src/interfaces/INFTFlashLoanReceiver.sol";
import {INFTExchange} from "../../src/interfaces/INFTExchange.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MaliciousNFTFlashLoanReceiver is INFTFlashLoanReceiver, IERC721Receiver {
    error NotReceived();

    INFTExchange public exchange;

    constructor(address _exchange) {
        exchange = INFTExchange(_exchange);
    }

    function executeOperation(address asset, uint256 assetId, address loanAsset, uint256 loanFee)
        external
        override
        returns (bool)
    {
        // Try relisting this NFT so we can cancel it and reclaim later, or purchase for 0
        exchange.createListing(
            INFTExchange.Listing(
                true,
                address(this),
                true,
                loanAsset,
                0,
                asset,
                assetId,
                address(0),
                0,
                false,
                address(0),
                address(0),
                0,
                0
            )
        );

        exchange.purchaseListing(1);

        IERC721(asset).safeTransferFrom(address(this), msg.sender, assetId, "");
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
