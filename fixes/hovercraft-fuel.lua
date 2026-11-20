-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["hovercraft-fuel-fix"] then return end

local vehicle_fuel_exists = data.raw["fuel-category"]["vehicle-fuel"] ~= nil

if not vehicle_fuel_exists then
  local hovercraft_names = {
    "hovercraft",
    "hovercraft-collision",
    "missile-hovercraft",
    "electric-hovercraft",
    "laser-hovercraft",
  }

  for _, name in pairs(hovercraft_names) do
    local prototype = data.raw.car[name]
    if prototype and prototype.energy_source and prototype.energy_source.fuel_categories then
      local new_categories = {}
      local needs_fix = false
      for _, category in pairs(prototype.energy_source.fuel_categories) do
        if category == "vehicle-fuel" then
          table.insert(new_categories, "chemical")
          needs_fix = true
        else
          table.insert(new_categories, category)
        end
      end
      if needs_fix then
        prototype.energy_source.fuel_categories = new_categories
      end
    end
  end
end
