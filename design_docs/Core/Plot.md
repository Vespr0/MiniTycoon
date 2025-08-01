#Core
## Overview

The plot is a 2D set of tiles assigned to each player when they join the server. The plot's form and placed items are saved, ensuring persistence across sessions.

---
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

---
## Placement System
You can place items on a 2D grid. No overlapping is allowed, this includes items at different heights on the same 2D grid.
