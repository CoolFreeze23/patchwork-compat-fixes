-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["hovercraft-fuel-fix"] then return end

-- Older Hovercrafts releases pointed the burner hovercrafts at a "vehicle-fuel"
-- fuel category that only exists with Krastorio 2 (and K2 2.1 renamed its
-- category to "kr-vehicle-fuel"), so without a matching category the
-- hovercraft could not be fuelled at all. Hovercrafts 2.1.x picks the
-- category itself ("kr-vehicle-fuel" with K2, "chemical" otherwise), so on
-- current releases this guard finds nothing to do. It still replaces any fuel
-- category a hovercraft names that no installed mod defines with "chemical".
local fuel_categories = data.raw["fuel-category"] or {}
if not fuel_categories["chemical"] then return end

local hovercraft_names = {
  "hovercraft",
  "hovercraft-collision",
  "missile-hovercraft",
  "electric-hovercraft",
  "laser-hovercraft",
}

for _, name in pairs(hovercraft_names) do
  local prototype = data.raw.car and data.raw.car[name]
  local source = prototype and prototype.energy_source
  if source and source.type == "burner" and source.fuel_categories then
    local new_categories, seen, needs_fix = {}, {}, false
    for _, category in pairs(source.fuel_categories) do
      if not fuel_categories[category] then
        category = "chemical"
        needs_fix = true
      end
      if not seen[category] then
        seen[category] = true
        new_categories[#new_categories + 1] = category
      end
    end
    if needs_fix then
      log("[patchwork/hovercraft-fuel] " .. name .. ": undefined fuel category replaced by chemical")
      source.fuel_categories = new_categories
    end
  end
end
