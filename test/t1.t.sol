// SPDX-Lisence-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {ConditionalTokens} from "src/ConditionalTokens.sol"; 
import {DeployConditional} from "script/DeployConditional.s.sol"; 
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol"; 
import {console} from "forge-std/console.sol";
// if a contract recieves ERC1155 tokens it must implement ERC11155Receiver
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";   


contract ConditionalTokensTest is Test, IERC1155Receiver {

    address ORACLE = makeAddr("randomOracleAddress");

    DeployConditional deployConditional; 
    ERC20Mock usdc; 
    ConditionalTokens conditionalTokens; 
    bytes32 questionId; 
    uint[] partition = new uint[](2); 
    uint[] payoutVector = new uint[](2); 

    function setUp() public {
        deployConditional = new DeployConditional(); 
        conditionalTokens = deployConditional.DeployConditionalTokens(); 
        usdc = new ERC20Mock(); // collateral token or the token on which the tokens will be transferred
        // questionId = abi.encodePacked("Will bitcoin hit 100K this month?");
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
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


function testSplitPosition() public {
    questionId = keccak256(abi.encodePacked("Will bitcoin hit 100K this month?")); 
    bytes32 conditionId = conditionalTokens.getConditionId(ORACLE, questionId, 2);
    bytes32 parentCollectionId = bytes32(0); 

    conditionalTokens.prepareCondition(ORACLE, questionId, 2);

    usdc.mint(address(this), 100); 
    emit log_uint(usdc.balanceOf(address(this)));
    usdc.approve(address(conditionalTokens), 100); 
    emit log_uint(usdc.allowance(address(this), address(conditionalTokens)));

    
    partition[0] = 1; // outcome 0b01
    partition[1] = 2; // outcome 0b10

    uint amount = 100; 

    console.log("Before split gas: ", gasleft());
    conditionalTokens.splitPosition(usdc, parentCollectionId, conditionId, partition, amount);
    console.log("After split gas: ", gasleft());

    uint positionIdA = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 1)
    );
    uint positionIdB = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 2)
    );

    assertEq(conditionalTokens.balanceOf(address(this), positionIdA), 100, "Should have 100 tokens of position A");
    assertEq(conditionalTokens.balanceOf(address(this), positionIdB), 100, "Should have 100 tokens of position B");

    assertEq(usdc.balanceOf(address(conditionalTokens)), 100, "Contract should be holding 100 USDC");
}



function testMergePosition() public {
    questionId = keccak256(abi.encodePacked("Will bitcoin hit 100K this month?")); 
    bytes32 conditionId = conditionalTokens.getConditionId(ORACLE, questionId, 2);
    bytes32 parentCollectionId = bytes32(0); 

    conditionalTokens.prepareCondition(ORACLE, questionId, 2);

    usdc.mint(address(this), 100); 
    emit log_uint(usdc.balanceOf(address(this)));
    usdc.approve(address(conditionalTokens), 100); 
    emit log_uint(usdc.allowance(address(this), address(conditionalTokens)));

    
    partition[0] = 1; // outcome 0b01
    partition[1] = 2; // outcome 0b10

    uint amount = 100; 

    conditionalTokens.splitPosition(usdc, parentCollectionId, conditionId, partition, amount);
    
        uint positionIdA = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 1)
    );

    uint positionIdB = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 2)
    );

    uint newAmount = 40; // try to redeem only 40 usdc

    conditionalTokens.mergePositions(usdc, parentCollectionId, conditionId, partition, newAmount);

    assertEq(conditionalTokens.balanceOf(address(this), positionIdA), 60, "Should have 60 tokens of position A");
    assertEq(conditionalTokens.balanceOf(address(this), positionIdB), 60, "Should have 60 tokens of position B");

    assertEq(usdc.balanceOf(address(this)), 40, "this Contract should be holding 40 USDC after redeeming the tokens");
}


function testRedeemPosition() public {  // reportPayoutfunction also working in this
        questionId = keccak256(abi.encodePacked("Will bitcoin hit 100K this month?")); 
    bytes32 conditionId = conditionalTokens.getConditionId(ORACLE, questionId, 2);
    bytes32 parentCollectionId = bytes32(0); 

    conditionalTokens.prepareCondition(ORACLE, questionId, 2);

    usdc.mint(address(this), 100); 
    emit log_uint(usdc.balanceOf(address(this)));
    usdc.approve(address(conditionalTokens), 100); 
    emit log_uint(usdc.allowance(address(this), address(conditionalTokens)));

    
    partition[0] = 1; // outcome 0b01
    partition[1] = 2; // outcome 0b10

    uint amount = 100; 

    conditionalTokens.splitPosition(usdc, parentCollectionId, conditionId, partition, amount);
    
        uint positionIdA = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 1)
    );

    uint positionIdB = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 2)
    );

    assertEq(usdc.balanceOf(address(this)), 0, "this Contract should be holding 0 USDC after splitting their position and before the reolution");

    // first the oracle calls reportPayouts to call set who won
    // Bitcoin does hit 100K this month hence the payout vector will be [1, 0]
    payoutVector[0] = 0; 
    payoutVector[1] = 1; 
    vm.prank(ORACLE);
    conditionalTokens.reportPayouts(questionId, payoutVector);
    vm.stopPrank();


    // after setting up the payouts now we call redeemPosition
    conditionalTokens.redeemPositions(usdc, parentCollectionId, conditionId, partition);

    // after redeeming position let's say I have 100 yes tokens so I wshould have 100 USDC back 
    assertEq(conditionalTokens.balanceOf(address(this), positionIdA), 0, "Should have 0 tokens of position A after redeeming");
    assertEq(conditionalTokens.balanceOf(address(this), positionIdB), 0, "Should have 0 tokens of position B after redeeming");

    assertEq(usdc.balanceOf(address(this)), 100, "this Contract should be holding 100 USDC after redeeming the tokens");
    
}

}
