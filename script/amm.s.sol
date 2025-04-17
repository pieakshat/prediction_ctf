// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {ConditionalTokens} from "src/ConditionalTokens.sol";
import {console} from "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    // this script is used by the AMM to call redeemPosition function 
contract ammCall is Script {

    address constant CONDITIONAL_TOKENS = 0x82BdAd4324E2E36C351FC9A74791DeD3E0d31F5A;
    address constant ORACLE = 0x7144b814a473017612Ac9f6Bbd287147e500953F;
    address constant AMM = 0x859C43d69021EB1784A1843E1adf8C999cf066A2;    

    uint[] partition = new uint[](2); 

    // the AMM already has 100 USDC earned as fees it is here to redeem it's position tokens for usdc
    // the redeem amount should be 10 USDC 
    // the script runs properly there is some issue in console.logs 
    function run() public {

    vm.startBroadcast();

    ConditionalTokens ct = ConditionalTokens(CONDITIONAL_TOKENS); 

    ERC20 usdc = ERC20(0x64dc93Ec94fb5D019C903703eB2deEe9dc0D25b2);     // mock usdc

    bytes32 questionId = keccak256(abi.encodePacked("Bitcoin 100K test?")); 
    bytes32 conditionId = ct.getConditionId(ORACLE, questionId, 2);
    bytes32 parentCollectionId = bytes32(0); 


    uint positionIdYes = ct.getPositionId(
        usdc, 
        ct.getCollectionId(parentCollectionId, conditionId, 1)
    );

    partition[0] = 1; // outcome 0b01
    partition[1] = 2; // outcome 0b10

    uint amountToBeRedeemed = ct.balanceOf(address(this), positionIdYes);    // Yes position is winning so that will be redeemed
    console.log(msg.sender);
    // console.log(amountToBeRedeemed);
    ct.redeemPositions(usdc, parentCollectionId, conditionId, partition); 

    uint finalUsdcBalance = usdc.balanceOf(address(this)); 

    // console.log(finalUsdcBalance);

    }
}