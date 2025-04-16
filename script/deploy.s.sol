// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {ConditionalTokens} from "src/ConditionalTokens.sol";

contract DeployConditional is Script {
    function run() public {
        vm.startBroadcast();
        new ConditionalTokens();
        vm.stopBroadcast();
    }
}
