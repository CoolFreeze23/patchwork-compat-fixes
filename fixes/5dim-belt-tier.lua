-- Defer to a standalone fix mod if one is installed.
if mods["5dim-belt-tier-fix"] then return end

-- 5dim_transport's underground-belt tiers (04-10) ship the vanilla express
-- reach (max_distance 9), but mods that extend the BASE undergrounds
-- (Krastorio 2 raises express to 20) don't touch the 5Dim copies - leaving
-- faster 5Dim belts with less than half the reach of the slower base belt.
-- Rescale by the base-vs-vanilla factor. The dedicated long-reach variants
-- (5d-*-underground-belt-30/-50) are their own design and are left alone.
local VANILLA_EXPRESS_UG_DISTANCE = 9

local base_ug = data.raw["underground-belt"] and data.raw["underground-belt"]["express-underground-belt"]
local mult = base_ug and base_ug.max_distance and (base_ug.max_distance / VANILLA_EXPRESS_UG_DISTANCE)
if mult and math.abs(mult - 1) > 1e-9 then
    for i = 4, 10 do
        local ug = data.raw["underground-belt"][string.format("5d-underground-belt-%02d", i)]
        if ug and ug.max_distance then
            local new_value = math.floor(ug.max_distance * mult + 0.5)
            log(string.format("[patchwork/belt-tier] %s: max_distance %d -> %d (x%.4g)",
                ug.name, ug.max_distance, new_value, mult))
            ug.max_distance = new_value
        end
    end
else
    log("[patchwork/belt-tier] base express underground unchanged from vanilla, tiers left as-is")
end
