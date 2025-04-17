// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {ConditionalTokens} from "src/ConditionalTokens.sol";
import {console} from "forge-std/console.sol";

    // this script is used by the oracle to send the decision after the event has occured
contract oracleCall is Script {

    address constant CONDITIONAL_TOKENS = 0x82BdAd4324E2E36C351FC9A74791DeD3E0d31F5A;
    address constant ORACLE = 0x7144b814a473017612Ac9f6Bbd287147e500953F;

    uint[] payoutVector = new uint[](2); 

    function run() public {
    vm.startBroadcast();

    ConditionalTokens ct = ConditionalTokens(CONDITIONAL_TOKENS); 

    console.log(msg.sender);
    bytes32 questionId = keccak256(abi.encodePacked("Bitcoin 100K test?"));

    payoutVector[0] = 1; // yes position wins
    payoutVector[1] = 0; 

    ct.reportPayouts(questionId, payoutVector);

    vm.stopBroadcast();
    }
}