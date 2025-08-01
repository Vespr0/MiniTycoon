# Plot System

## Overview

The plot is a 2D set of tiles assigned to each player when they join the server. The plot's form and placed items are saved, ensuring persistence across sessions.

## Terrain Generation

### Tile Composition
- **Tile Types**: Grass, sand, water, and more
- **Placement Rules**: Only some items can be placed on water tiles
- **Tile Size**: Square tiles with size (size, 1, size)
- **Special Cases**: Water tiles have additional thin parts underneath

### Procedural Generation
- **Seed**: Based on player's userID for consistency
- **Algorithm**: Perlin noise functions generate terrain
- **Features**: Oceans and rivers (perlin worms)
- **Bias**: System favors more land in center to avoid water-heavy starts

### Visual Design
- **Unconventional Approach**: Unlike typical concrete squares in genre
- **Ocean Boundary**: All plots surrounded by ocean
- **Consistency**: Same ocean represents both boundary and water tiles

## Placement System

### Grid Mechanics
- **Grid Size**: 0.5 units (smaller than tile size of 2)
- **Flexibility**: Multiple items per tile, or single item across multiple tiles
- **Usable Area**: Only portion of plot available initially

### Expansion System
- **Upgrades**: Plot area can be expanded through upgrades
- **Monetization**: Potential [[../Monetization/Plot-Expansions|revenue stream]]
- **Balance**: Must maintain [[../Balance/Progression|fair progression]]

## Technical Implementation

- **Persistence**: Plot state saved per player
- **Loading**: Consistent appearance across sessions  
- **Performance**: Optimized for multiplayer server environment

## Related Systems

- **[[Items]]** - What gets placed on plots
- **[[../Economy/Shop]]** - Where expansion upgrades are purchased
- **[[../Balance/Progression]]** - Expansion unlock progression
- **[[../Monetization/Plot-Expansions]]** - Premium expansion options