### Overview
The shop is the primary interface for acquiring items, featuring both a standard market and a dynamic offers system.

---
### Market Tab

### Basic Functionality
- **Categories**: Dropper, Belt, Forge, Decoration
- **Requirements**: Items purchasable for cash if player meets level requirement
- **Display**: Shows available items with prices and level gates

---
### Offers System

#### Core Mechanics
- **Timing**: New offers every 5 minutes
- **Quantity**: 8 items per offer cycle
- **Reset**: Offers completely refresh each cycle

#### Algorithm Details

#### Item Pools
Three distinct pools determine offer composition:
- **ITEMS POOL**: 5 items selected per cycle
- **UTILITY POOL**: 2 items selected per cycle  
- **SPECIAL POOL**: 1 item selected per cycle

#### Pool Configuration
Each pool contains: `[itemName] = {recommended level, luck factor}`

#### Weight Calculation
Algorithm considers:
- **Player Level**: Compared to item's recommended level
- **Ownership**: How many of specific item player already has
- **Luck Factor**: Random element for rarity control
- **Weight Distribution**: Higher weights = higher selection probability

#### Example Output
```
"Coal Mine: 32$, Coal Mine: 32$, Coal Mine: 32$, Coal Mine: 32$, 
Conveyor: 8$, Conveyor: 8$, Tree: 12$"
```

---
## Design Considerations

### Risk Assessment
- **==Unconventional==**: Differs from standard shop mechanics
- **Balance Challenge**: Complex algorithm difficult to balance
- **Player Impact**: May create confusion or frustration

### Integration Points
- **[[../Balance/Economy]]**: Requires careful economic balancing
- **[[../Monetization/Premium-Items]]**: Premium items may appear in offers
- **[[../Core/Progression]]**: Level affects offer generation

---
### Related Systems

- **[[../Core/Items]]** - What's being sold
- **[[../Core/Progression]]** - Level requirements and weighting
- **[[../Balance/Economy]]** - Economic balance considerations
- **[[../Monetization/Premium-Items]]** - Premium item integration