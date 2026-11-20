-- AutoDeconstruct's remove-target feature deconstructs a depleted drill's
-- output chest unless something it recognizes still drops into it - and it
-- only checks drop_target types (drill/inserter/assembler/furnace). LOADERS
-- attach via loader_container instead, so they are invisible to that check
-- (still true as of AutoDeconstruct 1.1.1) and a chest relaying a
-- loader->chest->loader transport chain gets torn out with the drill,
-- breaking the whole line. Guard: when a script marks a container for
-- deconstruction while a loader is connected to it and a depleted (or
-- already-marked) drill drops into it, cancel the mark. Player-made marks
-- (decon planner) are never touched.

if not script.active_mods["AutoDeconstruct"] then return end

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
