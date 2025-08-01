# Item System

## Overview

Items are objects placed by the player in their plot. They are stationary unless moved and serve different functions in the production chain.

## Item Types

### Droppers
- **Function**: Produce basic products/resources
- **Examples**: Ice generators, coal mines, iron mineral extractors, honey producers
- **Behavior**: Continuously generate base materials

### Upgraders  
- **Function**: Transform or enhance products
- **Types**:
  - **Value Upgraders**: Increase product worth (flat + or multiply *)
  - **Transformation Upgraders**: Convert basic resources into derivative products
- **Examples**: Oven (dough → bread), various processing machines
- **Timing**: Most work instantly, some "trap" products for delayed transformation
- **Visual Effects**: Some products receive visual effects during processing

### Forges
- **Function**: Sell products for cash on contact
- **Behavior**: Convert products to currency instantly
- **Integration**: Work with the [[../Economy/Stocks|stocks system]] for dynamic pricing

### Decorations
- **Function**: Aesthetic enhancement
- **Purpose**: Plot customization and visual appeal
- **Monetization**: Potential [[../Monetization/Cosmetics|cosmetic revenue stream]]

## Item Rarity System

Defined in `ItemInfo.lua`, items have different rarity tiers that affect:
- Availability in the [[../Economy/Shop|shop system]]
- Visual presentation
- [[../Balance/Progression|Unlock progression]]

**Implementation**: Rarity is stored in item's config as `config.Rarity` (string value)

## Related Systems

- **[[Plot]]** - Where items are placed
- **[[../Economy/Shop]]** - How items are acquired  
- **[[../Balance/Progression]]** - Item unlock progression
- **[[../Monetization/Premium-Items]]** - Premium item strategy