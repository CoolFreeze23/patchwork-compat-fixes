-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["loader-upgrade-fix"] then return end

-- The upgrade planner GUI pairs entities using the same predicate as next_upgrade
-- validation: same fast_replaceable_group AND identical collision geometry. Group
-- alignment alone (v1.0.0) was not enough - the pack's 1x1 loaders also differ in
-- collision box (Deadlock 0.26, K2 0.45 deep, rest 0.4) and collision mask (Deadlock
-- and Load-Furn block players; K2/5Dim/vanilla are walkable).
-- Normalize every land 1x1 loader to the vanilla loader-1x1 geometry, which K2 and
-- 5Dim already use verbatim. Side effect: Deadlock and loader-pro loaders become
-- walkable, like belts and the other loaders. SE space loaders stay untouched.
local reference = data.raw["loader-1x1"]["transport-belt-loader"]
local group = (reference and reference.fast_replaceable_group) or "transport-belt"
local skip = {
  ["kr-se-loader"] = true,
  ["kr-se-deep-space-loader-black"] = true,
}
for name, proto in pairs(data.raw["loader-1x1"] or {}) do
  if not skip[name] then
    proto.fast_replaceable_group = group
    proto.collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } }
    -- vanilla's mask is an engine default (not an explicit field), so set the
    -- equivalent explicitly on everyone. Only name layers that exist in this
    -- install: "space_tile"/"meltable" come from space mods and naming an
    -- unknown layer is a hard startup error in their absence.
    local layers = {}
    for _, layer in ipairs({ "floor", "meltable", "object", "transport_belt", "water_tile", "space_tile" }) do
      if data.raw["collision-layer"] and data.raw["collision-layer"][layer] then
        layers[layer] = true
      end
    end
    proto.collision_mask = { layers = layers }
  end
end
