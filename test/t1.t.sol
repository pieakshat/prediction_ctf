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
    address ammAddress = makeAddr("addressOfTheAMM");
    address PLATFORM = makeAddr("AddressOfPlatform");

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
    conditionalTokens.splitPosition(usdc, parentCollectionId, conditionId, partition, amount, ammAddress);
    console.log("After split gas: ", gasleft());

    uint positionIdA = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 1)
    );
    uint positionIdB = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 2)
    );

    assertEq(conditionalTokens.balanceOf(address(ammAddress), positionIdA), 100, "Should have 100 tokens of position A");
    assertEq(conditionalTokens.balanceOf(address(ammAddress), positionIdB), 100, "Should have 100 tokens of position B");

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

    // called by this contract 
    conditionalTokens.splitPosition(usdc, parentCollectionId, conditionId, partition, amount, ammAddress);
    
        uint positionIdA = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 1)
    );

    uint positionIdB = conditionalTokens.getPositionId(
        usdc, conditionalTokens.getCollectionId(parentCollectionId, conditionId, 2)
    );

    uint newAmount = 40; // try to redeem only 40 usdc

    // called by the amm contract 
    vm.prank(ammAddress);
    conditionalTokens.mergePositions(usdc, parentCollectionId, conditionId, partition, newAmount);
    vm.stopPrank();

    assertEq(conditionalTokens.balanceOf(address(ammAddress), positionIdA), 60, "Should have 60 tokens of position A");
    assertEq(conditionalTokens.balanceOf(address(ammAddress), positionIdB), 60, "Should have 60 tokens of position B");

    assertEq(usdc.balanceOf(address(ammAddress)), 40, "this Contract should be holding 40 USDC after redeeming the tokens");
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

    conditionalTokens.splitPosition(usdc, parentCollectionId, conditionId, partition, amount, ammAddress);
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
    vm.prank(ammAddress); 
    conditionalTokens.redeemPositions(usdc, parentCollectionId, conditionId, partition);
    vm.stopPrank();

    // after redeeming position let's say I have 100 yes tokens so I wshould have 100 USDC back 
    assertEq(conditionalTokens.balanceOf(address(ammAddress), positionIdA), 0, "Should have 0 tokens of position A after redeeming");
    assertEq(conditionalTokens.balanceOf(address(ammAddress), positionIdB), 0, "Should have 0 tokens of position B after redeeming");

    assertEq(usdc.balanceOf(address(ammAddress)), 100, "Amm Contract should be holding 100 USDC after redeeming the tokens");
    
}


function testCreatorCreatingCondition() public {  // reportPayoutfunction also working in this

    questionId = keccak256(abi.encodePacked("Will bitcoin hit 100K this month?")); 
    bytes32 conditionId = conditionalTokens.getConditionId(ORACLE, questionId, 2);
    bytes32 parentCollectionId = bytes32(0); 

    partition[0] = 1; // outcome 0b01
    partition[1] = 2; // outcome 0b10

    usdc.mint(address(this), 100); 
    usdc.approve(address(conditionalTokens), 100); 

    uint amount = 100; 

    conditionalTokens.creatorCreatingCondition(usdc, parentCollectionId, ORACLE, questionId, partition, amount, ammAddress);

    assertEq(conditionalTokens.creatorOfCondition(conditionId), address(this), "creatorOfCondition should be set to msg.sender");

    
    uint positionIdYes = conditionalTokens.getPositionId(
        usdc, 
        conditionalTokens.getCollectionId(parentCollectionId, conditionId, 1)
    );

    uint positionIdNo = conditionalTokens.getPositionId(
        usdc, 
        conditionalTokens.getCollectionId(parentCollectionId, conditionId, 2)
    );

    assertEq(conditionalTokens.balanceOf(ammAddress, positionIdYes), amount, "AMM should hold 100 YES tokens");
    assertEq(conditionalTokens.balanceOf(ammAddress, positionIdNo), amount, "AMM should hold 100 NO tokens");

    // after this is done let's say on the AMM's some trades happen and there are 30 yes left and let's say it earns 150 dollars in trading fees 
        // Simulate trades: AMM sells 70 YES tokens (users bought them)
    usdc.mint(address(ammAddress), 150); // $150 earned in trading fees
    vm.prank(ammAddress);
    conditionalTokens.safeTransferFrom(ammAddress, address(0xBEEF), positionIdYes, 70, "0x");       // 30 Yes shares still left in the AMM

    // yes position wins 
    payoutVector[0] = 1; 
    payoutVector[1] = 0; 
    // first oracle calls reportPayOuts()

    vm.prank(ORACLE);
    conditionalTokens.reportPayouts(questionId, payoutVector);
    vm.stopPrank();


    partition[0] = 1; // outcome 0b01
    partition[1] = 2; // outcome 0b10
    // now the amm will call the redeem position and collect all the usdc(worth 30 USDC)
    vm.prank(ammAddress);
    conditionalTokens.redeemPositions(usdc, parentCollectionId, conditionId, partition);
    vm.stopPrank();

    // AMM should receive 30 USDC (for 30 YES tokens)
    uint finalAmmBalance = usdc.balanceOf(ammAddress);
    assertEq(finalAmmBalance, 180, "AMM should have 180 USDC after redeeming 30 winning YES tokens");   // $150 + $30


    // AMM sends rewards
    // 20% to creator, 80% to platform
    uint creatorReward = (finalAmmBalance * 20) / 100;  // 20% going to the creator 
    uint platformShare = finalAmmBalance - creatorReward;


    // simulate AMM sending rewards
    vm.startPrank(ammAddress);
    usdc.transfer(address(this), creatorReward);    // to creator
    usdc.transfer(PLATFORM, platformShare);         // to platform
    vm.stopPrank();


    assertEq(usdc.balanceOf(address(this)), creatorReward, "Creator should receive 20% of profit");
    assertEq(usdc.balanceOf(PLATFORM), platformShare, "Platform should receive 80% of profit");


}



}
