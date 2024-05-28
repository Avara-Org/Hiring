// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {NFTExchange} from "../src/NFTExchange.sol";

contract NFTExchangeScript is Script {
    function run() public {
        vm.broadcast();
        new NFTExchange();
        vm.stopBroadcast();
    }
}
