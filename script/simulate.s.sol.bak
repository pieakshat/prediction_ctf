// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {ConditionalTokens} from "src/ConditionalTokens.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1000 * 1e6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract Simulate is Script {
    address constant CONDITIONAL_TOKENS = 0x82BdAd4324E2E36C351FC9A74791DeD3E0d31F5A; 
    address constant ORACLE = 0x7144b814a473017612Ac9f6Bbd287147e500953F;
    address constant AMM = 0x859C43d69021EB1784A1843E1adf8C999cf066A2;
    uint[] partition = new uint[](2); 

    function run() external {
        vm.startBroadcast();

        // Deploy mock USDC and approve
        MockUSDC usdc = new MockUSDC();
        usdc.approve(CONDITIONAL_TOKENS, 10 * 1e6);

        

        // Create the condition
        ConditionalTokens ct = ConditionalTokens(CONDITIONAL_TOKENS);
        bytes32 questionId = keccak256(abi.encodePacked("Bitcoin 100K test?"));
        bytes32 parentCollectionId = bytes32(0);

        partition[0] = 1; // YES
        partition[1] = 2; // NO
        uint amount = 10 * 1e6;

        ct.creatorCreatingCondition(
            usdc,
            parentCollectionId,
            ORACLE,
            questionId,
            partition,
            amount,
            AMM
        );

        vm.stopBroadcast();
    }
}
