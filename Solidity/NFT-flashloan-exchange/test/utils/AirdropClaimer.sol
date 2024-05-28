// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INFTFlashLoanReceiver} from "../../src/interfaces/INFTFlashLoanReceiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AirdropERC20} from "./AirdropERC20.sol";

contract AirdropClaimer is INFTFlashLoanReceiver, IERC721Receiver {
    IERC721 public requiredNFT;
    AirdropERC20 public airdropToken;

    error AirdropNotReceived();
    error IncorrectAsset();

    constructor(address _requiredNFT, address _airdropToken) {
        requiredNFT = IERC721(_requiredNFT);
        airdropToken = AirdropERC20(_airdropToken);
    }

    function executeOperation(address asset, uint256 assetId, address loanAsset, uint256 loanFee)
        external
        override
        returns (bool)
    {
        airdropToken.claimAirdrop(assetId);
        if (airdropToken.balanceOf(address(this)) != 1000e18) {
            revert AirdropNotReceived();
        }

        if (loanAsset != address(airdropToken)) {
            revert IncorrectAsset();
        }

        airdropToken.approve(address(msg.sender), loanFee);
        SafeERC20.safeTransfer(IERC20(airdropToken), msg.sender, loanFee);
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
