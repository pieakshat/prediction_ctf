// SPDX-Lisence-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol"; 
import {ConditionalTokens} from "src/ConditionalTokens.sol"; 
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {console} from "forge-std/console.sol";

contract ConditionalTokensTest is Test {
    ConditionalTokens ctf; 

    // mock collateral token 
    // deploy Conditional Tokens Contract 
    
    ERC20Mock usdc;  // mock collateral token 
    address user = makeAddr("user"); 
    address oracle = makeAddr("oracle"); 

    function setUp() public {
        usdc = new ERC20Mock(); 
        ctf = new ConditionalTokens(); 
    }

    function testCreatePosition() public {

        string memory question = "Will Bitcoin hit $115k this month?"; 

        uint outcomeSlotCount = 2; // yes/no 

        vm.startPrank(user); 
        ctf.prepareCondition(oracle, question, outcomeSlotCount);    
        vm.stopPrank(); 

        bytes32 conditionId = ctf.getConditionId(oracle, ctf.getQuestionId(question), outcomeSlotCount);

        require(ctf.creatorOfCondition(conditionId) == user, "Creator should be the user");
        uint length = ctf.getOutcomeSlotCount(conditionId);
        require(length == outcomeSlotCount, "Outcome slot count should be the same");      
    }


    function testSplitPosition() public {
        
        vm.prank(user);
        usdc.mint(user, 1000);
        // usdc.approve(address(ctf), 1000);

        string memory question = "Will Bitcoin hit $115k this month?"; 
        uint outcomeSlotCount = 2; // yes/no 

        bytes32 questionId = ctf.getQuestionId(question);
        bytes32 conditionId = ctf.getConditionId(oracle, questionId, outcomeSlotCount); 
        bytes32 parentCollectionId = bytes32(0); 
        bytes32 collectionIdA = ctf.getCollectionId(parentCollectionId, conditionId, 1);
        bytes32 collectionIdB = ctf.getCollectionId(parentCollectionId, conditionId, 2);
        uint positionIdA = ctf.getPositionId(usdc, collectionIdA);
        uint positionIdB = ctf.getPositionId(usdc, collectionIdB);

        vm.startPrank(user); 
        ctf.prepareCondition(oracle, question, outcomeSlotCount);    
        vm.stopPrank(); 

        uint[] memory partition = new uint[](2); 
        partition[0] = 1; // yes 
        partition[1] = 2; // no 

        uint amount = 500; 

        vm.startPrank(user); 
        usdc.approve(address(ctf), amount); 
        ctf.splitPosition(usdc, parentCollectionId, conditionId, partition, amount); 
        vm.stopPrank(); 

        uint balanceA = ctf.balanceOf(user, positionIdA); 
        uint balanceB = ctf.balanceOf(user, positionIdB); 

        require(balanceA == amount, "Balance of user should be the amount");
        require(balanceB == amount, "Balance of user should be the amount");

        uint balanceUsdc = usdc.balanceOf(address(ctf)); 
        require(balanceUsdc == amount, "Balance of contract should be the amount");
    }

    function testMergePosition() public {

        vm.prank(user);
        usdc.mint(user, 1000);
        

        string memory question = "Will Bitcoin hit $115k this month?"; 
        uint outcomeSlotCount = 2; // yes/no 

        bytes32 questionId = ctf.getQuestionId(question);
        bytes32 conditionId = ctf.getConditionId(oracle, questionId, outcomeSlotCount); 
        bytes32 parentCollectionId = bytes32(0); 
        bytes32 collectionIdA = ctf.getCollectionId(parentCollectionId, conditionId, 1);
        bytes32 collectionIdB = ctf.getCollectionId(parentCollectionId, conditionId, 2);
        uint positionIdA = ctf.getPositionId(usdc, collectionIdA);
        uint positionIdB = ctf.getPositionId(usdc, collectionIdB);

        vm.startPrank(user); 
        ctf.prepareCondition(oracle, question, outcomeSlotCount);    
        vm.stopPrank(); 

        uint[] memory partition = new uint[](2); 
        partition[0] = 1; // yes 
        partition[1] = 2; // no 

        uint amount = 500; 

        vm.startPrank(user); 
        usdc.approve(address(ctf), 1000);
        ctf.splitPosition(usdc, parentCollectionId, conditionId, partition, amount); 
        vm.stopPrank(); 

        uint balanceA = ctf.balanceOf(user, positionIdA); 
        uint balanceB = ctf.balanceOf(user, positionIdB); 
        
        require(balanceA == amount, "Balance of user should be the amount");
        require(balanceB == amount, "Balance of user should be the amount");

        uint balanceUsdc = usdc.balanceOf(address(ctf)); 
        require(balanceUsdc == amount, "Balance of contract should be the amount");

        vm.startPrank(user); 
        usdc.approve(address(ctf), amount);
        ctf.mergePositions(usdc, parentCollectionId, conditionId, partition, amount); 
        vm.stopPrank(); 

        uint balanceAAfterMerge = ctf.balanceOf(user, positionIdA); 
        uint balanceBAfterMerge = ctf.balanceOf(user, positionIdB); 
        
        require(balanceAAfterMerge == 0, "after merge Balance of user should be the 0");
        require(balanceBAfterMerge == 0, "after merge Balance of user should be the 0");

        uint balanceUsdcAfterMerge = usdc.balanceOf(address(ctf)); 
        require(balanceUsdcAfterMerge == 0, "Balance of contract should be the 0");
    }

    function testRedeemPosition() public {
                vm.prank(user);
        usdc.mint(user, 1000);
        

        string memory question = "Will Bitcoin hit $115k this month?"; 
        uint outcomeSlotCount = 2; // yes/no 

        bytes32 questionId = ctf.getQuestionId(question);
        bytes32 conditionId = ctf.getConditionId(oracle, questionId, outcomeSlotCount); 
        bytes32 parentCollectionId = bytes32(0); 
        bytes32 collectionIdA = ctf.getCollectionId(parentCollectionId, conditionId, 1);
        bytes32 collectionIdB = ctf.getCollectionId(parentCollectionId, conditionId, 2);
        uint positionIdA = ctf.getPositionId(usdc, collectionIdA); // yes position
        uint positionIdB = ctf.getPositionId(usdc, collectionIdB); // no position 

        vm.startPrank(user); 
        ctf.prepareCondition(oracle, question, outcomeSlotCount);    
        vm.stopPrank(); 

        uint[] memory partition = new uint[](2); 
        partition[0] = 1; // yes 
        partition[1] = 2; // no 

        uint amount = 500; 

        vm.startPrank(user); 
        usdc.approve(address(ctf), 1000);
        ctf.splitPosition(usdc, parentCollectionId, conditionId, partition, amount); 
        vm.stopPrank(); 

        uint balanceA = ctf.balanceOf(user, positionIdA); 
        uint balanceB = ctf.balanceOf(user, positionIdB); 
        
        require(balanceA == amount, "Balance of user should be the amount");
        require(balanceB == amount, "Balance of user should be the amount");

        uint balanceUsdc = usdc.balanceOf(address(ctf)); 
        require(balanceUsdc == amount, "Balance of contract should be the amount");

        uint[] memory payoutVector = new uint[](2); 
        payoutVector[0] = 0; // yes
        payoutVector[1] = 1; // no 

        vm.startPrank(oracle); 
        ctf.reportPayouts(questionId, payoutVector); // answer is no 
        vm.stopPrank(); 

        vm.prank(user); 
        ctf.redeemPositions(usdc, parentCollectionId, conditionId, partition);
        vm.stopPrank(); 

        uint balanceUsdcAfterRedeem = usdc.balanceOf(user); 
        require(balanceUsdcAfterRedeem == 1000, "Balance of user should be the amount"); // did no trade, got the orignal tokens back 
        
        uint balanceyesTokenYesAfterRedeem = ctf.balanceOf(user, positionIdA); 
        require(balanceyesTokenYesAfterRedeem == 0, "Balance of yes token should be the 0");

        uint balancenoTokenNoAfterRedeem = ctf.balanceOf(user, positionIdB); 
        require(balancenoTokenNoAfterRedeem == 0, "Balance of no token should be the 0");

        uint ctfBalanceUsdcAfterRedeem = usdc.balanceOf(address(ctf)); 
        require(ctfBalanceUsdcAfterRedeem == 0, "Balance of contract should be the 0");
    }
}