# Stocks System

## Overview

The stocks system adds strategic depth through dynamic product pricing based on supply and demand mechanics.

**Status**: Not yet implemented (simulated in `StocksSimulator.lua`)

## Core Mechanics

### Supply & Demand
- **High Sales Volume**: Product price decreases
- **Low Sales Volume**: Product price increases when other products sell
- **Market Response**: Real-time price adjustments based on player behavior

### Price Constraints
- **Decimal Precision**: Prices rounded to 1 decimal place for simplicity
- **Starter Products**: Fixed prices to ensure stable basic progression
- **Price Floors**: Prevent products from becoming worthless

## Player Experience

### Instant Sales
- **No Inventory**: Players cannot hold products
- **Immediate Conversion**: Products sell instantly at current stock value when reaching forge
- **Real-time Pricing**: Players see current market prices

### Strategic Depth
- **Timing Decisions**: When to sell becomes important
- **Product Selection**: Which products to focus on based on market conditions
- **Market Awareness**: Players must monitor price trends

## Accessibility Design

### Optional Engagement
- **Ignorable System**: Players can ignore stocks and still profit
- **Complexity Management**: Ensures young/inexperienced players aren't overwhelmed
- **Progressive Complexity**: Advanced players can engage deeply

### UI Integration
- **Shop Display**: Stock prices shown in shop section
- **Visual Indicators**: Clear price trend indicators
- **Market Overview**: Summary of current market conditions

## Technical Implementation

### Simulation Engine
- **File**: `StocksSimulator.lua`
- **Real-time Updates**: Continuous price recalculation
- **Server Synchronization**: All players see same market state

### Balance Integration
- **[[../Balance/Economy]]**: Requires careful economic balancing
- **Progression Impact**: Must not break [[../Core/Progression|level progression]]
- **Monetization**: Should not favor [[../Monetization/Premium-Items|premium items]]

## Future Enhancements

- **Market Events**: Special events affecting prices
- **Product Categories**: Different volatility for different product types
- **Player Analytics**: Tracking market participation

## Related Systems

- **[[../Core/Items#Forges]]** - Where products are sold
- **[[Shop]]** - Where stock prices are displayed
- **[[../Balance/Economy]]** - Economic balance requirements
- **[[../Core/Progression]]** - Must maintain fair progression