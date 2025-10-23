# Prediction Market CTF Implementation

## Overview
Conditional Token Framework (CTF) implementation for prediction markets using ERC1155 tokens and AMM integration.

## Core Components

### ConditionalTokens Contract
- **Purpose**: Manages prediction market conditions and position tokens
- **Inherits**: ERC1155 for token management
- **Key Functions**:
  - `prepareCondition()`: Creates new prediction market
  - `splitPosition()`: Converts collateral into outcome tokens
  - `mergePositions()`: Combines outcome tokens back to collateral
  - `redeemPositions()`: Redeems winning tokens after resolution

### ID System
- **conditionId**: `keccak256(oracle + questionId + outcomeSlotCount)`
- **collectionId**: `keccak256(parentCollectionId + conditionId + indexSet)`
- **positionId**: `keccak256(collateralToken + collectionId)`

## Current Architecture Issues

### Problem
- Tokens minted directly to AMM address
- Users cannot acquire tokens for trading
- No mechanism for users to participate in markets

### Current Flow (Broken)
```
User deposits USDC → CTF mints YES/NO tokens → AMM holds all tokens
❌ Users can't trade because they don't have tokens
```

## Proposed Better Architecture

### Improved Flow
```
User deposits USDC → CTF mints YES/NO tokens → Users get tokens
LP deposits USDC → AMM gets liquidity → Users trade tokens on AMM
✅ Users have tokens to trade, AMM has liquidity to facilitate trading
```

### Key Changes
1. **Token Distribution**: Mint tokens to users, not AMM
2. **Liquidity Provision**: Separate LP mechanism for AMM
3. **Pricing**: `price(YES) + price(NO) = 1` (constant sum)

## Implementation Requirements

### Missing Components
1. **AMM Contract**: For token trading and liquidity management
2. **LP Functions**: For liquidity provision
3. **Trading Interface**: Buy/sell functions for users
4. **Price Discovery**: Constant sum pricing mechanism

### Required Functions
```solidity
// AMM Contract
function buyTokens(uint positionId, uint amount, uint maxPrice)
function sellTokens(uint positionId, uint amount, uint minPrice)
function addLiquidity(uint amount)
function getPrice(uint positionId)
```

## User Journey

1. **Market Creation**: Creator sets up condition and provides initial liquidity
2. **Position Creation**: User deposits collateral, gets outcome tokens
3. **Trading**: User trades tokens on AMM with LP liquidity
4. **Resolution**: Oracle reports results, users redeem winning tokens

## Benefits of Proposed Architecture

- **User Ownership**: Users actually own tradeable tokens
- **Proper Liquidity**: AMM has USDC for trading operations
- **Efficient Pricing**: Constant sum constraint ensures proper price discovery
- **LP Rewards**: Liquidity providers earn trading fees
- **Market Efficiency**: Reflects true market sentiment without arbitrage


on the AMM I need to have an initializePool Function that will be called after the a bet is created. 

CTF Contract is only to mint yes/no against collateral token(USDC). 


Hierarchial relationship between conditionId collectionId and positionId

```
conditionId (Question: "Will Bitcoin hit $100K?")
├── collectionId (Outcome: "YES" - indexSet=1)
│   └── positionId (USDC-backed YES tokens)
├── collectionId (Outcome: "NO" - indexSet=2)
│   └── positionId (USDC-backed NO tokens)
└── collectionId (Outcome: "YES|NO" - indexSet=3)
    └── positionId (USDC-backed YES|NO tokens)
```