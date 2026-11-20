-- Defer to a standalone fix mod if one is installed.
if mods["5dim-belt-tier-fix"] then return end

-- 5dim_transport's underground-belt tiers (04-10) ship the vanilla express
-- reach (max_distance 9), but mods that extend the BASE undergrounds
-- (Krastorio 2 raises express to 20) don't touch the 5Dim copies - leaving
-- faster 5Dim belts with less than half the reach of the slower base belt.
-- Rescale by the base-vs-vanilla factor. The dedicated long-reach variants
-- (5d-*-underground-belt-30/-50) are their own design and are left alone.
local VANILLA_EXPRESS_UG_DISTANCE = 9 -- 5dim_transport 2.1.x: 3 + 2 * tier (04 -> 11 ... 10 -> 23)

local base_ug = data.raw["underground-belt"] and data.raw["underground-belt"]["express-underground-belt"]
local mult = base_ug and base_ug.max_distance and (base_ug.max_distance / VANILLA_EXPRESS_UG_DISTANCE)
-- Double-scale guard: the first 5Dim tier still having LESS reach than a
-- raised base express underground proves the tiers are vanilla-derived. If it
-- already reaches the base value, 5Dim (or another mod) already follows the
-- base and rescaling again would double-scale.
local first_tier = data.raw["underground-belt"] and data.raw["underground-belt"]["5d-underground-belt-04"]
if mult and mult > 1 and first_tier and first_tier.max_distance
    and first_tier.max_distance >= base_ug.max_distance then
    log(string.format("[patchwork/belt-tier] 5d-underground-belt-04 reach %d already reaches the base express reach %d - tiers already follow the base, left as-is",
        first_tier.max_distance, base_ug.max_distance))
elseif mult and mult < 1 then
    log("[patchwork/belt-tier] base express underground reach was lowered, tiers left as-is")
elseif mult and math.abs(mult - 1) > 1e-9 then
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
