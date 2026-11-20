-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["5dim-furnace-smelting-fix"] then return end

-- 5Dim / modded furnace smelting compatibility fix.
--
-- Goal: every 5Dim furnace (and the mini-machines "mini furnace") should be able to
-- run all the smelting recipes the base furnaces and the Advanced Furnaces 2 mod can,
-- INCLUDING multi-ingredient ones such as Krastorio 2's coke (coal + wood -> coke).
--
-- Why this is more than just copying categories:
--   * A `furnace`-type entity has a single input slot and auto-selects its recipe from
--     the inserted item, so it can NEVER craft a recipe with two ingredients (like coke).
--   * Krastorio 2 solves this by converting every "smelting" furnace into an
--     `assembling-machine` (manual recipe selection, multiple input slots). It does this
--     at the data-updates stage.
--   * Any smelting furnace created AFTER that pass (the mini furnaces, made at
--     data-final-fixes) or that lacked the "smelting" category at the time (the 5Dim
--     industrial furnace) is missed by K2 and stays a plain furnace -> can't make coke.
--
-- This file runs at data-final-fixes, after K2 and mini-machines (see the optional
-- dependencies in info.json), so it sees the final state. For each target furnace it
-- grants the smelting categories and, if the target is still a `furnace`, converts it
-- to an assembling-machine exactly the way K2 does.

local raw = data.raw
local furnaces = raw["furnace"]
local assemblers = raw["assembling-machine"]

-- Find a machine prototype by name in either the furnace or assembling-machine table.
local function find_machine(name)
  if furnaces and furnaces[name] then return furnaces[name] end
  if assemblers and assemblers[name] then return assemblers[name] end
  return nil
end

-- 1) Collect the set of smelting categories to grant. Seed with "smelting" so the core
--    category is always present, then add whatever the base furnaces and the Advanced
--    Furnaces 2 machines support (each may be a furnace OR, post-K2, an assembler).
local category_set = { ["smelting"] = true }

local source_names = {
  "stone-furnace", "steel-furnace", "electric-furnace",
  "furnace-pro-01", "furnace-pro-02", "furnace-pro-03", "furnace-pro-04", "furnace-pro-05",
}
for _, name in ipairs(source_names) do
  local ent = find_machine(name)
  if ent and ent.crafting_categories then
    for _, category in ipairs(ent.crafting_categories) do
      category_set[category] = true
    end
  end
end

-- Merge the collected categories into a machine (no duplicates, keeps existing ones).
local function merge_categories(ent)
  local categories = ent.crafting_categories or {}
  local present = {}
  for _, category in ipairs(categories) do
    present[category] = true
  end
  for category in pairs(category_set) do
    if not present[category] then
      categories[#categories + 1] = category
      present[category] = true
    end
  end
  ent.crafting_categories = categories
end

-- Convert a furnace-type prototype into an assembling-machine, mirroring how
-- Krastorio 2 does it (data-util.lua `furnace_to_assembler`). This is what lets
-- multi-ingredient smelting recipes be selected and crafted.
local function furnace_to_assembler(furnace)
  local assembler = table.deepcopy(furnace)
  assembler.type = "assembling-machine"
  assembler.source_inventory_size = nil
  assembler.result_inventory_size = nil
  furnaces[furnace.name] = nil
  data:extend({ assembler })
  return assemblers[furnace.name]
end

-- Detect whether this modpack makes smelting assembler-based (Krastorio 2 and similar
-- convert the vanilla electric furnace into an assembling-machine). Only then is the
-- furnace->assembler conversion wanted: without it, furnaces should stay auto-smelters.
local smelting_is_assembler_based = assemblers and assemblers["electric-furnace"] ~= nil

-- 2) Build the list of target machines: every 5Dim furnace plus the mini-machines
--    mini furnaces (mini-furnace-1 .. mini-furnace-N; loop a generous range, nil-safe).
local targets = {}
for i = 1, 10 do
  targets[#targets + 1] = string.format("5d-electric-furnace-%02d", i)
end
targets[#targets + 1] = "5d-industrial-furnace"
for i = 1, 20 do
  targets[#targets + 1] = "mini-furnace-" .. i
end
-- Advanced Furnaces 2 (furnace-pro-01..05). These are already assembling-machines, but
-- Load-Furn gives them a fixed category list (smelting/AdvFurn/mixing-furnace/chemical-
-- furnace) that is missing "kiln" -- the category Krastorio 2 actually puts coke in --
-- so they get the full smelting set merged in here too.
for i = 1, 5 do
  targets[#targets + 1] = string.format("furnace-pro-%02d", i)
end

-- 3) For each target: grant the smelting categories, and if it is still a furnace,
--    convert it to an assembling-machine so it can run multi-ingredient recipes.
for _, name in ipairs(targets) do
  if furnaces and furnaces[name] then
    merge_categories(furnaces[name])
    if smelting_is_assembler_based then
      furnace_to_assembler(furnaces[name])
    end
  elseif assemblers and assemblers[name] then
    -- Already an assembling-machine (e.g. Krastorio 2 already converted it):
    -- just make sure it has every smelting category.
    merge_categories(assemblers[name])
  end
end
