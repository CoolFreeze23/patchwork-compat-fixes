-- Defer to a standalone fix mod if one is installed.
if mods["5dim-turret-tier-fix"] then return end

-- 5dim_battlefield's gun/laser turret tiers derive range and damage from the
-- vanilla turrets (gun range 18, laser range 24 / damage_modifier 2), but
-- Krastorio 2 rebalances the BASE turrets (gun 25, laser 30 / damage_modifier
-- 3) - so the first 5Dim tiers have LESS range than the base turret they
-- replace, and laser tier 2 (x2.9) hits weaker than the base laser (x3).
-- Rescale by the base-vs-vanilla factors. (Ammo flight range is handled by the
-- sniper-range module, which runs after this one; 5Dim tesla turrets have no
-- base counterpart.)
local VANILLA_GUN_RANGE = 18
local VANILLA_LASER_RANGE = 24
local VANILLA_LASER_DAMAGE_MOD = 2 -- vanilla laser-turret damage_modifier (5Dim tiers: 2 x 1.45^n)

-- Double-scale guard: a tier-2 value still BELOW a raised base value proves the
-- tiers are vanilla-derived. If it already reaches the base value, 5Dim (or
-- another mod) already follows the base turret and rescaling would double-scale.
-- Lowered base stats cannot be told apart this way and are left alone.
local function should_scale(family, field, mult, tier2_value, base_value)
    if not mult or math.abs(mult - 1) <= 1e-9 then return false end
    if mult < 1 then
        log(string.format("[patchwork/turret-tier] %s %s: base value was lowered, tiers left as-is", family, field))
        return false
    end
    if type(tier2_value) ~= "number" or type(base_value) ~= "number" or tier2_value >= base_value then
        log(string.format("[patchwork/turret-tier] %s %s: tier 2 %s already reaches the base %s - tiers already follow the base, left as-is",
            family, field, tostring(tier2_value), tostring(base_value)))
        return false
    end
    return true
end
local function ap_of(proto) return proto and proto.attack_parameters or {} end

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
local gun_t2 = data.raw["ammo-turret"] and data.raw["ammo-turret"]["5d-gun-turret-02"]
if gun_mult and math.abs(gun_mult - 1) > 1e-9 then
    if should_scale("gun", "range", gun_mult, ap_of(gun_t2).range, gun_ap.range) then
        for i = 2, 10 do
            local t = data.raw["ammo-turret"][string.format("5d-gun-turret-%02d", i)]
            if t then scale_ap(t, "range", gun_mult) end
        end
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
    local laser_t2 = data.raw["electric-turret"]["5d-laser-turret-02"]
    local do_range = should_scale("laser", "range", lrange_mult, ap_of(laser_t2).range, laser_ap.range)
    local do_damage = should_scale("laser", "damage_modifier", ldmg_mult,
        ap_of(laser_t2).damage_modifier or (laser_t2 and 1), laser_ap.damage_modifier or 1)
    for i = 2, 10 do
        local t = data.raw["electric-turret"][string.format("5d-laser-turret-%02d", i)]
        if t then
            if do_range then scale_ap(t, "range", lrange_mult) end
            if do_damage then scale_ap(t, "damage_modifier", ldmg_mult) end
        end
    end
else
    log("[patchwork/turret-tier] base laser-turret unchanged from vanilla, tiers left as-is")
end
