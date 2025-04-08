// SPDX-Lisence-Identifier: MIT
pragma solidity ^0.5.17;

import {Script} from "forge-std/Test.sol";
import {ConditionalTokens} from "src/ConditionalTokens.sol"; 

contract DeployConditional is Script {

    function run() public {}


    function DeployConditionalTokens() publi returns(ConditionalTokens) {
        vm.startBroadcast(msg.sender); 
        ConditionalTokens conditionalTokens = new ConditionalTokens(); 
        vm.stopBroadcast(); 

        return conditionalTokens; 
    }
}