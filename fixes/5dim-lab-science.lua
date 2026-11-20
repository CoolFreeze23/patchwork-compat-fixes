-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["5dim-lab-science-fix"] then return end

-- 5dim_automation's lab tiers copy the vanilla lab's science-pack list at
-- generation time, so packs that overhaul mods add to the base lab later
-- (Krastorio 2's kr-basic-tech-card, SE's rocket science pack) never reach the
-- 5Dim tiers - every technology needing one of them is unresearchable in an
-- upgraded lab. Grant every 5Dim lab (and biolab) tier all packs the base lab
-- (biolab) accepts. The tier's own packs are kept: base labs in overhaul packs
-- are often deliberately limited (K2's basic lab stops at chemical science),
-- and replacing the list would strip production/utility/space packs from
-- the high 5Dim tiers.

local function merge_inputs(lab, extra)
  local inputs = lab.inputs or {}
  local present = {}
  for _, pack in ipairs(inputs) do present[pack] = true end
  for _, pack in ipairs(extra) do
    if not present[pack] then
      inputs[#inputs + 1] = pack
      present[pack] = true
    end
  end
  lab.inputs = inputs
end

local function sync_tiers(base_name, format_pattern)
  local base = data.raw["lab"] and data.raw["lab"][base_name]
  if not (base and base.inputs) then return end
  for i = 2, 10 do
    local lab = data.raw["lab"][string.format(format_pattern, i)]
    if lab then merge_inputs(lab, base.inputs) end
  end
end

sync_tiers("lab", "5d-lab-%02d")
sync_tiers("biolab", "5d-biolab-%02d")
