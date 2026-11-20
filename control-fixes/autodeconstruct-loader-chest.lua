-- AutoDeconstruct's remove-target feature deconstructs a depleted drill's
-- output chest unless something it recognizes still drops into it - and up to
-- 1.1.1 it only checked drop_target types (drill/inserter/assembler/furnace).
-- LOADERS attach via loader_container instead, so they were invisible to that
-- check and a chest relaying a loader->chest->loader transport chain got torn
-- out with the drill, breaking the whole line. Guard: when a script marks a
-- container for deconstruction while a loader is connected to it and a
-- depleted (or already-marked) drill drops into it, cancel the mark.
-- Player-made marks (decon planner) are never touched.
--
-- AutoDeconstruct 1.1.2 (the first release for Factorio 2.1) counts input
-- loaders as item sources itself, so relay chests are kept upstream. On top
-- of that release the guard would only cancel marks AutoDeconstruct now places
-- on purpose (a dead chest drained by an output loader), so it stands down.

local version = script.active_mods["AutoDeconstruct"]
if not version then return end

local function older_than(v, ref)
  local a, b = {}, {}
  for n in string.gmatch(v, "%d+") do a[#a + 1] = tonumber(n) end
  for n in string.gmatch(ref, "%d+") do b[#b + 1] = tonumber(n) end
  for i = 1, math.max(#a, #b) do
    local x, y = a[i] or 0, b[i] or 0
    if x ~= y then return x < y end
  end
  return false
end

if not older_than(version, "1.1.2") then return end

local LOADER_SEARCH = 3 -- loaders touch the chest; 3 tiles covers any loader size
local DRILL_SEARCH = 8  -- drop_position reach of the largest modded drills

local function area_around(pos, r)
  return {{pos.x - r, pos.y - r}, {pos.x + r, pos.y + r}}
end

local function has_connected_loader(chest)
  for _, l in pairs(chest.surface.find_entities_filtered{
    type = {"loader", "loader-1x1"}, area = area_around(chest.position, LOADER_SEARCH)}) do
    if l.loader_container == chest then return true end
  end
  return false
end

local function fed_by_depleted_drill(chest)
  for _, d in pairs(chest.surface.find_entities_filtered{
    type = "mining-drill", area = area_around(chest.position, DRILL_SEARCH)}) do
    if d.drop_target == chest then
      local res = d.mining_target
      if d.to_be_deconstructed() or not (res and res.valid and res.amount > 0) then
        return true
      end
    end
  end
  return false
end

script.on_event(defines.events.on_marked_for_deconstruction, function(event)
  if event.player_index then return end -- only script-made marks
  local chest = event.entity
  if not (chest and chest.valid) then return end
  if has_connected_loader(chest) and fed_by_depleted_drill(chest) then
    chest.cancel_deconstruction(chest.force)
    log(string.format("[patchwork/autodeconstruct-loader-chest] preserved %s at %.1f,%.1f",
      chest.name, chest.position.x, chest.position.y))
  end
end, {
  {filter = "type", type = "container"},
  {filter = "type", type = "logistic-container"},
  {filter = "type", type = "linked-container"},
})
