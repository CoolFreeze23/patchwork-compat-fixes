-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["loader-upgrade-fix"] then return end

-- The upgrade planner GUI pairs entities using the same predicate as next_upgrade
-- validation: same fast_replaceable_group AND identical collision geometry. Group
-- alignment alone (v1.0.0) was not enough - the pack's 1x1 loaders also differ in
-- collision box (Deadlock 0.26, K2 0.45 deep, rest 0.4) and collision mask (Deadlock
-- and Load-Furn block players; K2/5Dim/vanilla are walkable).
-- Normalize every land 1x1 loader to the vanilla loader-1x1 geometry, which 5Dim
-- uses verbatim (Krastorio 2 2.1 ships a 0.45-deep box and its own group). Side effect: Deadlock and loader-pro loaders become
-- walkable, like belts and the other loaders. SE space loaders stay untouched.
-- The reference is the vanilla loader-1x1 (2.1 has no "transport-belt-loader").
-- Its mask is the engine default unless a mod (SE's postprocess) set one, so
-- the shared mask is: the reference's explicit mask, else the default mask the
-- engine would give a loader-1x1, else the vanilla layer set filtered against
-- the layers that exist (naming an unknown layer is a hard startup error).
local loaders = data.raw["loader-1x1"] or {}
local reference = loaders["loader-1x1"]
local group = (reference and reference.fast_replaceable_group) or "transport-belt"
local skip = {
  ["kr-se-loader"] = true,
  ["kr-se-deep-space-loader-black"] = true,
}

local function shared_mask()
  if reference and reference.collision_mask then
    return reference.collision_mask
  end
  local constants = data.raw["utility-constants"] and data.raw["utility-constants"]["default"]
  local defaults = constants and constants.default_collision_masks
  if defaults and defaults["loader-1x1"] then
    return defaults["loader-1x1"]
  end
  local layers = {}
  for _, layer in ipairs({ "floor", "meltable", "object", "transport_belt", "water_tile", "space_tile" }) do
    if data.raw["collision-layer"] and data.raw["collision-layer"][layer] then
      layers[layer] = true
    end
  end
  return { layers = layers }
end

local mask = shared_mask()
for name, proto in pairs(loaders) do
  if not skip[name] then
    proto.fast_replaceable_group = group
    proto.collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } }
    proto.collision_mask = table.deepcopy(mask)
  end
end
