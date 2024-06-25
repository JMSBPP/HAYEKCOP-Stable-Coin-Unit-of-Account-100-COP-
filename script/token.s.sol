// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HAYEKCOP} from "../src/token.sol";

contract deployHAYEKCOP is Script {
    function run() external {
        vm.startBroadcast();

        new HAYEKCOP();

        vm.stopBroadcast();
    }
}
