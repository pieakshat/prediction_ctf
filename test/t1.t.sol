// SPDX-Lisence-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {ConditionalTokens} from "src/ConditionalTokens.sol"; 
import {DeployConditional} from "script/DeployConditional.s.sol"; 
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol"; 


contract ConditionalTokensTest is Test {

    address ORACLE = makeAddr("randomOracleAddress");

    DeployConditional deployConditional; 
    ERC20Mock usdc; 
    ConditionalTokens conditionalTokens; 
    bytes32 questionId; 

    function setUp() public {
        deployConditional = new DeployConditional(); 
        conditionalTokens = deployConditional.DeployConditionalTokens(); 
        usdc = new ERC20Mock(); // collateral token or the token on which the tokens will be transferred
        // questionId = abi.encodePacked("Will bitcoin hit 100K this month?");
    }

    function testprepareCondition() public {
        // setting up a question Id
        questionId = keccak256(abi.encodePacked("Will bitcoin hit 100K this month?")); 

        // calculate the expected conditionId
        bytes32 conditionId = conditionalTokens.getConditionId(ORACLE, questionId, 2);

        vm.startBroadcast();
        conditionalTokens.prepareCondition(ORACLE, questionId, 2); 
        vm.stopBroadcast();

        // checking if the condition is properly initialised
        uint outcomeSlots = conditionalTokens.getOutcomeSlotCount(conditionId); 
        assertEq(outcomeSlots, 2, "Outcome Slots should be 2"); 

        // checking if payout numerator is initialised
        for (uint i = 0; i < 2; i++) {
            assertEq(conditionalTokens.payoutNumerators(conditionId, i), 0, "Numerator should be initialised to 0");
        }

        // check that denominator is still zero 
        assertEq(conditionalTokens.payoutDenominator(conditionId), 0, "Payout denominator should be zero before resolving anything");

    }
}