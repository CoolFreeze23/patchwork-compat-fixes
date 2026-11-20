-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["some-spidertron-grid-fix"] then return end

-- some-spidertron enlarges "spidertron-equipment-grid", but Krastorio 2 points the
-- spidertron at "kr-spidertron-equipment-grid" instead, and Spidertron Extended's
-- data-final-fixes re-sizes that grid from its own startup settings. This mod loads
-- after both (via dependencies) and copies the enlarged size onto the grid in use.
local source = data.raw["equipment-grid"]["spidertron-equipment-grid"]
local spidertron = data.raw["spider-vehicle"]["spidertron"]

if source and spidertron and spidertron.equipment_grid then
  local target = data.raw["equipment-grid"][spidertron.equipment_grid]
  if target and target ~= source then
    target.width = source.width
    target.height = source.height
  end
end
