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
    address constant CONDITIONAL_TOKENS = 0x368E19f65cb5aB2E94538D3068CD4BbC147C2A96;
    address constant ORACLE = address(0x0A12CE);
    address constant AMM = address(0xA11CE);
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
