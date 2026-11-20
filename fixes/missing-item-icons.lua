-- Items left with neither `icon` nor `icons` (a hard prototype error at the end of the data stage).
--
-- Cause seen on Factorio 2.1: 5Dim Logistic gives the vanilla roboport (and other tiered entities) an
-- `icons` list with a tier badge, but Factorissimo builds its hidden factory-construction-roboport item
-- by copying `data.raw.item["roboport"].icon`, which is now nil. Any other mod that copies a single
-- `icon` from an item 5Dim re-badged hits the same error.
--
-- Fix: for every item-type prototype with no icon at all, copy the icon from the item it was built
-- from (known pairs below), otherwise from the entity it places. Does nothing when every item already
-- has an icon.

local item_types = {
  "item", "item-with-entity-data", "item-with-inventory", "item-with-label", "item-with-tags",
  "ammo", "armor", "capsule", "gun", "module", "rail-planner", "repair-tool", "selection-tool",
  "space-platform-starter-pack", "spidertron-remote", "tool", "blueprint", "blueprint-book",
  "copy-paste-tool", "deconstruction-item", "upgrade-item",
}

-- item name -> item it copies its icon from
local known_sources = {
  ["factory-construction-roboport"] = "roboport",
  ["factory-hidden-construction-robot"] = "construction-robot",
}

local function find_item(name)
  for _, t in pairs(item_types) do
    local p = data.raw[t] and data.raw[t][name]
    if p then return p end
  end
end

local function copy_icon(to, from)
  if not from then return false end
  if from.icons then
    to.icons = table.deepcopy(from.icons)
    return true
  elseif from.icon then
    to.icon = from.icon
    to.icon_size = from.icon_size
    return true
  end
  return false
end

local function find_entity(name)
  for _, group in pairs(data.raw) do
    local p = group[name]
    if p and p.collision_box ~= nil and (p.icon or p.icons) then return p end
  end
end

local fixed = {}
for _, t in pairs(item_types) do
  for name, item in pairs(data.raw[t] or {}) do
    if item.icon == nil and item.icons == nil then
      local ok = copy_icon(item, known_sources[name] and find_item(known_sources[name]))
      if not ok and item.place_result then
        ok = copy_icon(item, find_entity(item.place_result))
      end
      if ok then fixed[#fixed + 1] = name end
    end
  end
end

if #fixed > 0 then
  log("Patchwork missing-item-icons: gave icons to " .. table.concat(fixed, ", "))
end
