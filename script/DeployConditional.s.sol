// SPDX-Lisence-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {ConditionalTokens} from "src/ConditionalTokens.sol"; 

contract DeployConditional is Script {

    function run() public {}


    function DeployConditionalTokens() public returns(ConditionalTokens) {
        vm.startBroadcast(msg.sender); 
        ConditionalTokens conditionalTokens = new ConditionalTokens(); 
        vm.stopBroadcast(); 

        return conditionalTokens; 
    }
}