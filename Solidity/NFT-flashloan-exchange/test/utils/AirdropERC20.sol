// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AirdropERC20 is ERC20 {
    IERC721 public requiredNFT;
    mapping(uint256 => bool) public claimed;

    error Ineligible();
    error AlreadyClaimed();

    constructor(address _requiredNFT) ERC20("Airdrop", "AIR") {
        requiredNFT = IERC721(_requiredNFT);
    }

    function claimAirdrop(uint256 tokenId) public {
        _checkEligibility(tokenId);
        claimed[tokenId] = true;
        _mint(msg.sender, 1000e18);
    }

    function _checkEligibility(uint256 tokenId) internal view returns (bool) {
        if (claimed[tokenId]) {
            revert AlreadyClaimed();
        }
        if (!(requiredNFT.ownerOf(tokenId) == msg.sender)) {
            revert Ineligible();
        }
        return true;
    }
}
