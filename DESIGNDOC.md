### The Base

Mini tycoon is a sandbox tycoon with unique features and mechanics. The selling point is
a sandbox tycoon that's not linear and "boring" like Miners Haven but a dynamic and
engaging approach that transforms the genre from a mostly incremental game to a strategy incremental one. So the focus is on adding strategy. This means making more aspects of the game like the plot and the items more complex.

---

### The Audience

The game is made for all audiences both very young and old. This means it should be simple to play but have deeper elements for those who crave them, without complicating the game.

—

### The Gameplay

The gameplay loop is: place items, earn cash, buy items, repeat.
[Cash is the main currency of the game.]
You have a plot where you place items and earn cash by selling the products you produce.
[An item is an object placed by the player in their plot, it is stationary unless moved and can be of various types , the main types are “Dropper”,”Forge”,”Upgrader”,”Decoration”].

[A dropper is an item that produces product]

[Product is generated by droppers and can take many forms. Droppers create essential resources like ice, coal, iron minerals, honey, etc. Upgraders can transform these basic resources into derivative products like bread (dough + going through an oven upgrader)]

[Forges are items that sell products for cash on contact.]

[A plot is an area that is assigned to the player when they join the server, however it’s form and items placed in it are saved so every time you join the plot will look the same.]

[Upgraders are items that can either increase a product's value or transform basic resources into derivative products through processing (e.g., turning dough into bread via an oven upgrader). Value upgraders can add flat amounts (+) or multiply (*) the product's worth. Most upgraders work instantly, but some may "trap" the product and transform it after a short delay (like an oven). On the client side, some products may receive visual effects even when not being transformed.]

There is a simple leveling system. You gain [XP] by selling [Product]. Using a formula you level up upon reaching a certain amount of [XP]. (XP is reset when you level up).
[XP are Experience points]

—

### Item Rarity System

Defined in `ItemInfo.lua` Items have different rarity tiers that affect their availability and visual presentation:
- **Common** (White) - Standard items available to most players
- **Rare** (Blue) - Less common items with better stats or unique features  
- **Collector's** (Red) - Limited or unobtainable items.
- **Unusual** (Purple) - Rare items with unique mechanics.
- **Admin** (Dark Blue) - Special administrative items

—

### The Plot

The plot is a 2D set of tiles , where only a portion that can be expanded with upgrades is usable by the player, only in that area can the player place items.
The set of tiles is composed of grass, sand, water and more. Only some items can be placed on water.
More specifically based on a seed [The seed is the userID of the player] perlin noise functions generate terrain with an ocean and rivers (pelrin worms) (the system is biased towards putting more land in the center this is to avoid player starting out in water or with a lot of water).

Most games of the genre have a plain concrete square, so this is an unconventional approach but not absurd as it is a pretty simple idea that has been done before just in different genres.
[A tile is a square part with size (size,1,size). In some specific cases it can have a more complex description but it will still be square and have the same height. For example: The water also has a thin part at the bottom under the blue water part]

The actual placement system works in a grid, but the grid size is 0.5, smaller than the tile size which is 2 at the time of writing this. This means multiple items can be on the same tile, or one item can be on top of multiple tiles.

---

### The Shop

The shop is probably the most unconventional and risky mechanic I’ve implemented for the game (from the developer perspective not the player’s). Usually games of the genre but also games with similar contexts have a linear shop where you see all the items or at least most of them ordered by price, so you know what to do, you know what you are gonna but next, you know what you are saving for.

The shop first tab is the Market. In the market you can select between different item types "Dropper, Belt, Forge, Decoration" and see the items that you can buy for X amount of [Cash] , if you are above a certain [Level].

In Mini Tycoon the shop also has an “offers” system where every 5 minutes 8 items are proposed to you (offers get reset every time). A complex algorithm chooses both the items and the prices based on your current level, how many of a specific item you have and also a random element to make certain items rarer based on three lists, “ITEMS POOL” , “UTILITY POOL” and “SPECIAL POOL”. These lists contain: [itemName] = {recommended level,luck factor}.

The algorithm then calculates weight based on the recommended level and luck factor in relation to the other variables mentioned earlier. The items for the offers are chosen by picking random weights (If an item has more weights it’s more likely to be chosen). More specifically it chooses 5 from the item pool, 2 from the utility pool and 1 from 0the special pool.
For example it may generate “Coal Mine : 32$,Coal Mine : 32$,Coal Mine : 32$,Coal Mine : 32$, Conveyor 8$, Conveyor 8$, Tree: 12$”
This system is risky because it’s unconventional and hard to balance.

---

### The Stocks

I want to add a stocks system , already simulated in `StocksSimulator.lua` where the sell value of a product can go up and down based on how much is sold, in a supply demand fascion. If a product is sold a lot then it's price goes down, if a product isn't sold much it's price goes up when other product is sold.

It's a simple simulation but it offers more strategic depth.

This stocks will be displayed in a section inside the Shop. Players **cannot hold product**; it sells instantly at the current stock value upon reaching a forge. Starter products will have **fixed prices** to ensure basic progression remains stable.

The system is partially optional when you think about it, since the player could just ignore the system and still profit. This ensures young or unexperienced players aren't overwhelmed.

---

### The Stocks Simulator

The stocks system is designed to add a layer of strategic depth to the game, simulating a real-time market for the products players sell. Implemented in `StocksSimulator.lua`, the system adjusts the sell value of products based on their demand: if a product is sold frequently, its price decreases, and vice versa. This creates a dynamic where players must consider not only what products to sell but also when to sell them, adding a strategic layer to the gameplay.

The prices will have only 1 decimal value to further simplify the system (round to the nearest decimal).
