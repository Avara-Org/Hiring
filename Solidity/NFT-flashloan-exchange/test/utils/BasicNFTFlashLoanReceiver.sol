// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INFTFlashLoanReceiver} from "../../src/interfaces/INFTFlashLoanReceiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BasicNFTFlashLoanReceiver is INFTFlashLoanReceiver, IERC721Receiver {
    error NotReceived();

    function executeOperation(address asset, uint256 assetId, address loanAsset, uint256 loanFee)
        external
        override
        returns (bool)
    {
        if (IERC721(asset).ownerOf(assetId) != address(this)) {
            revert NotReceived();
        }

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
