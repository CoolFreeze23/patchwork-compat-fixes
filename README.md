# Patchwork — Cross-Mod Compatibility Fixes

Big modpacks are stitched together from mods that never met each other. Patchwork is a collection of small, targeted fixes for the seams between popular mods (Krastorio 2, Space Exploration, 5Dim, Mini Machines, Advanced Furnaces 2, Factorissimo, spidertron and loader mods). Every fix switches itself off when the mods it fixes aren't installed, and the rescaling fixes check that the bug is really there before touching anything, so it is safe in any pack.

## What it fixes

| Fix | Problem |
|---|---|
| 5Dim labs | Higher 5Dim lab tiers reject science packs other mods add (K2 tech cards, SE rocket science). Labs now accept every pack the base lab accepts. |
| Furnace smelting | Some 5Dim, Mini Machines and Advanced Furnaces 2 furnaces miss smelting categories (K2 coke, SE "kiln") or stay single-input furnaces. Grants the categories and converts furnaces to assemblers the way K2 does. |
| Sniper range | K2 bullets are projectiles capped at 30 tiles, so long-range turrets fire at targets their bullets can't reach. Projectile reach is raised to the longest turret range per ammo category. |
| 5Dim tiers follow the base | 5Dim tiers are generated from vanilla numbers; after K2 rebalances the base entity, "upgrades" can be weaker than the base. Rescales solar panels, accumulators, locomotives, underground belts, gun and laser turrets, reactors and heat exchangers by the base entity's change. |
| Spidertron grid | K2 swaps the spidertron's equipment grid, so some-spidertron's bigger grid never applies. The grid actually in use gets the size. |
| Advanced Furnaces 2 productivity | Its wood-to-coal and direct steel recipes rejected productivity modules. |
| Loader upgrades | 1×1 loaders from different mods use different upgrade groups and collision boxes, so the upgrade planner won't pair them. Normalizes them to the vanilla loader. |
| Loader circuits | Loaders from Deadlock, Advanced Furnaces 2 and 5Dim had no circuit wire reach. |
| Belt underground dragging | Advanced Furnaces 2 pro belts weren't paired with their undergrounds for smart belt dragging. |
| Missing item icons | On Factorio 2.1, 5Dim re-badges the roboport icon and Factorissimo's hidden construction roboport ended up with no icon, which stopped the game from loading. |
| Hovercraft fuel | Older Hovercrafts versions used a fuel category that might not exist; only acts if the category is undefined. |
| AutoDeconstruct loader chests | Older AutoDeconstruct versions removed relay chests between loaders when a drill ran out; the guard stands down on AutoDeconstruct 1.1.2+, which handles this itself. |

The full per-fix details and measured before/after values are in [changelog.txt](changelog.txt).

## Versions

| Factorio | Patchwork |
|---|---|
| 2.1 | 1.1.0 |
| 2.0 | 1.0.4 |

Install from the [mod portal](https://mods.factorio.com/mod/patchwork-compat-fixes) or copy this folder into your `mods` folder as `patchwork-compat-fixes_<version>`.

License: MIT
