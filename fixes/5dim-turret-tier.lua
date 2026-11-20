-- Defer to a standalone fix mod if one is installed.
if mods["5dim-turret-tier-fix"] then return end

-- 5dim_battlefield's gun/laser turret tiers derive range and damage from the
-- vanilla turrets (gun range 18, laser range 24 / damage x1), but Krastorio 2
-- rebalances the BASE turrets (gun 25, laser 30 / damage x3) - so the first
-- 5Dim tiers have LESS range than the base turret they replace, and every
-- laser tier does a third of its intended relative damage. Rescale by the
-- base-vs-vanilla factors. (Ammo flight range is already handled separately
-- by the sniper-range module; 5Dim tesla turrets have no base counterpart.)
local VANILLA_GUN_RANGE = 18
local VANILLA_LASER_RANGE = 24
local VANILLA_LASER_DAMAGE_MOD = 1

local function scale_ap(turret, field, mult)
    local ap = turret.attack_parameters
    if not ap or not ap[field] then return end
    local old = ap[field]
    local new_value = old * mult
    if field == "range" then new_value = math.floor(new_value + 0.5) end
    log(string.format("[patchwork/turret-tier] %s: %s %s -> %s (x%.4g)",
        turret.name, field, tostring(old), tostring(new_value), mult))
    ap[field] = new_value
end

local base_gun = data.raw["ammo-turret"] and data.raw["ammo-turret"]["gun-turret"]
local gun_ap = base_gun and base_gun.attack_parameters
local gun_mult = gun_ap and gun_ap.range and (gun_ap.range / VANILLA_GUN_RANGE)
if gun_mult and math.abs(gun_mult - 1) > 1e-9 then
    for i = 2, 10 do
        local t = data.raw["ammo-turret"][string.format("5d-gun-turret-%02d", i)]
        if t then scale_ap(t, "range", gun_mult) end
    end
else
    log("[patchwork/turret-tier] base gun-turret unchanged from vanilla, tiers left as-is")
end

local base_laser = data.raw["electric-turret"] and data.raw["electric-turret"]["laser-turret"]
local laser_ap = base_laser and base_laser.attack_parameters
local lrange_mult = laser_ap and laser_ap.range and (laser_ap.range / VANILLA_LASER_RANGE)
local ldmg_mult = laser_ap and (laser_ap.damage_modifier or 1) / VANILLA_LASER_DAMAGE_MOD
if (lrange_mult and math.abs(lrange_mult - 1) > 1e-9)
    or (ldmg_mult and math.abs(ldmg_mult - 1) > 1e-9) then
    for i = 2, 10 do
        local t = data.raw["electric-turret"][string.format("5d-laser-turret-%02d", i)]
        if t then
            if lrange_mult and math.abs(lrange_mult - 1) > 1e-9 then
                scale_ap(t, "range", lrange_mult)
            end
            if ldmg_mult and math.abs(ldmg_mult - 1) > 1e-9 then
                scale_ap(t, "damage_modifier", ldmg_mult)
            end
        end
    end
else
    log("[patchwork/turret-tier] base laser-turret unchanged from vanilla, tiers left as-is")
end
