-- Patchwork data stage: fixes that other mods' data-updates and data-final-fixes must already see.
-- Items with no icon (Factorissimo copying a single `icon` from an item 5Dim re-badged with `icons`):
-- the recycler builds recycling recipes from item icons in its data-updates, and Long Range Delivery
-- Drones builds particles from them in its data-final-fixes, so the icon has to exist by the end of
-- the data stage. Patchwork's optional dependencies make this run after Factorissimo's data.lua;
-- the module runs again at data-final-fixes for items created later.
require("fixes.missing-item-icons")
