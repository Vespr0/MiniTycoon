# Mini Tycoon Design Documentation Index

Welcome to the Mini Tycoon design documentation. This index provides an overview of all design documents and their interconnections.

## Main Overview

### [[Overview]] - Game Overview
High-level vision, audience, and core gameplay loop with links to detailed system documentation.

## Documentation Structure

### Core Systems (`/Core/`)
- **[[Core/Items]]** - Item types, rarity system, and mechanics
- **[[Core/Plot]]** - Terrain generation, placement system, and expansion
- **[[Core/Progression]]** - Leveling, XP mechanics, and advancement

### Economy Systems (`/Economy/`)
- **[[Economy/Shop]]** - Market interface and offers algorithm
- **[[Economy/Stocks]]** - Dynamic pricing and market simulation

### Balance & Progression (`/Balance/`)
- **[[Balance/Overview]]** - Balance philosophy and key areas
- **[[Balance/Progression]]** - Level system and unlock balance
- **[[Balance/Economy]]** - Economic balance and currency flow
- **[[Balance/Difficulty]]** - Challenge scaling and accessibility
- **[[Balance/Player-Retention]]** - Long-term engagement systems

### Monetization Strategy (`/Monetization/`)
- **[[Monetization/Overview]]** - Monetization strategy and philosophy
- **[[Monetization/Philosophy]]** - Ethical guidelines and principles
- **[[Monetization/Premium-Items]]** - Premium item strategy
- **[[Monetization/Plot-Expansions]]** - Plot expansion monetization
- **[[Monetization/Cosmetics]]** - Cosmetic items and customization
- **[[Monetization/Quality-of-Life]]** - Convenience features

## System Interconnections

### Core Gameplay Flow
- **[[Overview]]** → **[[Core/Items]]** → **[[Economy/Shop]]** → **[[Balance/Economy]]**
- **[[Core/Plot]]** → **[[Monetization/Plot-Expansions]]** → **[[Balance/Progression]]**

### Progression & Balance
- **[[Core/Progression]]** ↔ **[[Balance/Progression]]** ↔ **[[Balance/Player-Retention]]**
- **[[Economy/Stocks]]** → **[[Balance/Economy]]** → **[[Monetization/Philosophy]]**

### Monetization Integration
- All **[[Monetization/]]** docs align with **[[Balance/Overview]]** and **[[Monetization/Philosophy]]**
- **[[Core/Items]]** rarity system affects **[[Monetization/Premium-Items]]**

## Quick Navigation

- **Getting Started** → [[Overview]]
- **Core Mechanics** → [[Core/Items]], [[Core/Plot]], [[Core/Progression]]
- **Economic Systems** → [[Economy/Shop]], [[Economy/Stocks]]
- **Game Balance** → [[Balance/Overview]]
- **Business Model** → [[Monetization/Overview]]

---

*This documentation is organized for easy navigation between interconnected game systems.*