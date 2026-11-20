-- Defer to a standalone fix mod if one is installed (prevents double
-- application; the fix is otherwise idempotent-safe on its own).
if mods["5dim-train-tier-fix"] then return end

-- 5dim_trains generates its locomotive tiers at data stage by copying the
-- vanilla prototype and writing absolute stats derived from vanilla's values:
--   locomotive: max_power 600kW + 100kW per tier, weight 2000 + 500 per tier
-- Mods that rebalance the BASE locomotive afterwards (Krastorio 2 sets it to
-- 2MW / 10000 weight / braking 30) don't touch the 5Dim copies, so every 5Dim
-- tier - including tier 10 at 1.5MW - ends up with LESS pulling power than the
-- base engine, and "upgrading" a train makes it accelerate worse.
--
-- Fix: compute how much each base stat was changed relative to the vanilla
-- value the 5Dim progression was built from, and rescale every 5Dim tier by
-- that same factor (power, weight, braking force and top speed each use their
-- own factor). Each tier keeps its intended percentage over tier 1 regardless
-- of which mod (or combination) rebalanced the base engine. With Krastorio 2
-- this yields 2.33MW/12500 (tier 02) up to 5MW/32500 (tier 10): every tier
-- out-pulls the base engine again and loaded-train acceleration ascends with
-- tier for any realistic consist.

-- Vanilla values 5dim_trains derives its progression from (2.1.x: hardcoded
-- 600kW / 2000 / braking 10 / speed 1.2, power x1.75 and weight/speed x1.45 per tier)
local VANILLA_LOCO_POWER_W = 600e3 -- 600kW
local VANILLA_LOCO_WEIGHT = 2000
local VANILLA_LOCO_BRAKING = 10
local VANILLA_LOCO_MAX_SPEED = 1.2

local SI_PREFIX = { k = 1e3, K = 1e3, M = 1e6, G = 1e9, T = 1e12, P = 1e15 }

-- "700kW" -> 700000, "W"; returns nil for anything it can't parse
local function parse_energy(value)
    if type(value) ~= "string" then return nil end
    local num, prefix, unit = value:match("^(%d+%.?%d*)([kKMGTP]?)([WJ])$")
    if not num then return nil end
    return tonumber(num) * (SI_PREFIX[prefix] or 1), unit
end

local function number_multiplier(current, vanilla_number)
    if type(current) ~= "number" or current <= 0 then return nil end
    local mult = current / vanilla_number
    if math.abs(mult - 1) < 1e-9 then return nil end
    return mult
end

local function energy_multiplier(current_value, vanilla_number)
    local current = parse_energy(current_value)
    if not current or current <= 0 then return nil end
    local mult = current / vanilla_number
    if math.abs(mult - 1) < 1e-9 then return nil end
    return mult
end

local function scale_energy(entity_name, field_desc, value, mult)
    local n, unit = parse_energy(value)
    if not n then
        log("[patchwork/train-tier] " .. entity_name .. ": cannot parse " ..
            field_desc .. " '" .. tostring(value) .. "', skipped")
        return nil
    end
    local new_value = string.format("%.0f", n * mult) .. unit
    log(string.format("[patchwork/train-tier] %s: %s %s -> %s (x%.4g)",
        entity_name, field_desc, tostring(value), new_value, mult))
    return new_value
end

local function scale_number(entity_name, field_desc, value, mult)
    if type(value) ~= "number" then return nil end
    local new_value = value * mult
    log(string.format("[patchwork/train-tier] %s: %s %s -> %s (x%.4g)",
        entity_name, field_desc, tostring(value), tostring(new_value), mult))
    return new_value
end

-- Locomotives ----------------------------------------------------------------

local base_loco = data.raw["locomotive"] and data.raw["locomotive"]["locomotive"]
local power_mult = base_loco and energy_multiplier(base_loco.max_power, VANILLA_LOCO_POWER_W)
local weight_mult = base_loco and number_multiplier(base_loco.weight, VANILLA_LOCO_WEIGHT)
local braking_mult = base_loco and number_multiplier(base_loco.braking_force, VANILLA_LOCO_BRAKING)
local speed_mult = base_loco and number_multiplier(base_loco.max_speed, VANILLA_LOCO_MAX_SPEED)

-- Double-scale guard: 5Dim writes vanilla-derived absolute stats, so a tier-2
-- value still BELOW a raised base value proves nobody rebalanced the tiers.
-- If any raised stat of tier 2 already reaches the base value, 5Dim (or
-- another mod) already follows the rebalanced base engine and rescaling would
-- double-scale. Lowered stats (K2's top speed) follow that same decision.
local function tiers_still_vanilla(tier2)
    if not tier2 then return false end
    local checks = {
        { "max_power", power_mult, parse_energy(tier2.max_power), parse_energy(base_loco.max_power) },
        { "weight", weight_mult, tier2.weight, base_loco.weight },
        { "braking_force", braking_mult, tier2.braking_force, base_loco.braking_force },
        { "max_speed", speed_mult, tier2.max_speed, base_loco.max_speed },
    }
    local raised = 0
    for _, c in ipairs(checks) do
        local field, mult, t2, base = c[1], c[2], c[3], c[4]
        if mult and mult > 1 then
            raised = raised + 1
            if not (type(t2) == "number" and type(base) == "number" and t2 < base) then
                log(string.format("[patchwork/train-tier] tier 2 %s %s already reaches the base %s - tiers already follow the base engine, left as-is",
                    field, tostring(t2), tostring(base)))
                return false
            end
        end
    end
    if raised == 0 then
        log("[patchwork/train-tier] base locomotive stats were only lowered, tiers left as-is")
        return false
    end
    return true
end

if not (power_mult or weight_mult or braking_mult or speed_mult) then
    log("[patchwork/train-tier] base locomotive unchanged from vanilla, locomotive tiers left as-is")
elseif tiers_still_vanilla(data.raw["locomotive"]["5d-locomotive-02"]) then
    for i = 2, 10 do
        local loco = data.raw["locomotive"][string.format("5d-locomotive-%02d", i)]
        if loco then
            if power_mult then
                loco.max_power = scale_energy(loco.name, "max_power", loco.max_power, power_mult)
                    or loco.max_power
            end
            if weight_mult then
                loco.weight = math.floor((scale_number(loco.name, "weight", loco.weight, weight_mult)
                    or loco.weight) + 0.5)
            end
            if braking_mult then
                loco.braking_force = scale_number(loco.name, "braking_force", loco.braking_force, braking_mult)
                    or loco.braking_force
            end
            if speed_mult then
                loco.max_speed = scale_number(loco.name, "max_speed", loco.max_speed, speed_mult)
                    or loco.max_speed
            end
        end
    end
end
