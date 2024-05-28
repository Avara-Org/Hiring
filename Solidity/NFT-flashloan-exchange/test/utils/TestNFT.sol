// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {
    constructor() ERC721("TestNFT", "NFT") {}

    function mint(address receiver, uint256 tokenId) public {
        _safeMint(receiver, tokenId);
    }
}
