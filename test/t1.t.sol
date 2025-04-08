// SPDX-Lisence-Identifier: MIT
pragma solidity ^0.5.17;



import {Test} from "forge-std/Test.sol";
import {ConditionalTokens} from "src/ConditionalTokens.sol"; 
import {DeployConditional} from "scripts/DeployConditional.s.sol"; 
import {ERC20Mock} from "openzeppelin-contracts/mocks/ERC20Mock.sol"; 


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
        questionId = abi.encodePacked("Will bitcoin hit 100K this month?");
    }

    function testprepareCondition() public {
        vm.startBroadcast();
        conditionalTokens.prepareCondition(ORACLE, questionId, 2); 
        vm.stopBroadcast();
    }
}