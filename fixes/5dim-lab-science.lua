-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["5dim-lab-science-fix"] then return end

local vanilla_lab = data.raw["lab"]["lab"]
if not vanilla_lab then return end

local vanilla_inputs = vanilla_lab.inputs
if not vanilla_inputs then return end

local function sync_inputs(base_name, format_pattern, tier_start, tier_end)
  for i = tier_start, tier_end do
    local name = string.format(format_pattern, i)
    local lab = data.raw["lab"][name]
    if lab then
      lab.inputs = table.deepcopy(vanilla_inputs)
    end
  end
end

sync_inputs("5d-lab", "5d-lab-%02d", 2, 10)

if data.raw["lab"]["biolab"] then
  local biolab_inputs = data.raw["lab"]["biolab"].inputs
  if biolab_inputs then
    for i = 2, 10 do
      local name = string.format("5d-biolab-%02d", i)
      local lab = data.raw["lab"][name]
      if lab then
        lab.inputs = table.deepcopy(biolab_inputs)
      end
    end
  end
end
