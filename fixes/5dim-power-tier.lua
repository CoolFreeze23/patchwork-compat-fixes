-- Defer to a standalone fix mod if one is installed.
if mods["5dim-power-tier-fix"] then return end

-- 5Dim's nuclear reactor and heat exchanger tiers (5dim_nuclear) derive from vanilla
-- (reactor 40MW / neighbour bonus 1; heat exchanger 10MW @ 500C), but
-- Krastorio 2 rebalances the BASE prototypes (reactor 250MW / bonus 0.25;
-- heat exchanger 50MW @ 415C) - so EVERY 5Dim reactor tier makes less heat
-- than the base reactor, and 5Dim heat exchangers under-convert at the wrong
-- steam temperature. Rescale by the base-vs-vanilla factors; the reactor
-- neighbour bonus and the exchanger's steam temperature follow the base
-- entity's values so the whole nuclear loop stays on one balance system.
local VANILLA_REACTOR_CONSUMPTION_W = 40e6 -- 40MW
local VANILLA_REACTOR_NEIGHBOUR_BONUS = 1
local VANILLA_HEATEX_CONSUMPTION_W = 10e6 -- 10MW

local SI_PREFIX = { k = 1e3, K = 1e3, M = 1e6, G = 1e9, T = 1e12, P = 1e15 }
local function parse_energy(value)
    if type(value) ~= "string" then return nil end
    local num, prefix, unit = value:match("^(%d+%.?%d*)([kKMGTP]?)([WJ])$")
    if not num then return nil end
    return tonumber(num) * (SI_PREFIX[prefix] or 1), unit
end

local function scale_energy(entity_name, field_desc, value, mult)
    local n, unit = parse_energy(value)
    if not n then
        log("[patchwork/power-tier] " .. entity_name .. ": cannot parse " ..
            field_desc .. " '" .. tostring(value) .. "', skipped")
        return nil
    end
    local new_value = string.format("%.0f", n * mult) .. unit
    log(string.format("[patchwork/power-tier] %s: %s %s -> %s (x%.4g)",
        entity_name, field_desc, tostring(value), new_value, mult))
    return new_value
end

-- Double-scale guard: a tier-2 value still BELOW a raised base value proves the
-- tiers are vanilla-derived. If tier 2 already reaches the base, 5Dim (or
-- another mod) already follows the base entity and rescaling would
-- double-scale. Lowered base values cannot be told apart and are left alone.
local function tiers_still_vanilla(family, mult, tier2_value, base_value)
    if mult < 1 then
        log("[patchwork/power-tier] base " .. family .. " was lowered, tiers left as-is")
        return false
    end
    local t2, base = parse_energy(tier2_value), parse_energy(base_value)
    if not (t2 and base and t2 < base) then
        log(string.format("[patchwork/power-tier] %s tier 2 %s already reaches the base %s - tiers already follow the base, left as-is",
            family, tostring(tier2_value), tostring(base_value)))
        return false
    end
    return true
end

-- Nuclear reactors ------------------------------------------------------------
-- (Factorio 2.1: reactors bond through neighbour_connectable instead of touching
-- edges; 5Dim tiers are deep copies of the base reactor and inherit its
-- connection points, so only consumption and neighbour_bonus are adjusted.)

local function scale_reactors(mult, bonus)
    for i = 2, 10 do
        local r = data.raw["reactor"][string.format("5d-nuclear-reactor-%02d", i)]
        if r then
            r.consumption = scale_energy(r.name, "consumption", r.consumption, mult) or r.consumption
            if bonus and math.abs(bonus - 1) > 1e-9 then
                local old = r.neighbour_bonus or 1
                r.neighbour_bonus = old * bonus
                log(string.format("[patchwork/power-tier] %s: neighbour_bonus %s -> %s (x%.4g)",
                    r.name, tostring(old), tostring(r.neighbour_bonus), bonus))
            end
        end
    end
end

local base_reactor = data.raw["reactor"] and data.raw["reactor"]["nuclear-reactor"]
local rc = base_reactor and parse_energy(base_reactor.consumption)
local cons_mult = rc and rc / VANILLA_REACTOR_CONSUMPTION_W
local bonus_mult = base_reactor and
    ((base_reactor.neighbour_bonus or 1) / VANILLA_REACTOR_NEIGHBOUR_BONUS)
local reactor_t2 = data.raw["reactor"] and data.raw["reactor"]["5d-nuclear-reactor-02"]

if not (cons_mult and math.abs(cons_mult - 1) > 1e-9) then
    log("[patchwork/power-tier] base nuclear-reactor unchanged from vanilla, tiers left as-is")
elseif reactor_t2 and tiers_still_vanilla("nuclear-reactor", cons_mult,
        reactor_t2.consumption, base_reactor.consumption) then
    scale_reactors(cons_mult, bonus_mult)
end

-- Heat exchangers --------------------------------------------------------------

local function scale_heat_exchangers(mult, base_hx)
    for i = 2, 10 do
        local hx = data.raw["boiler"][string.format("5d-heat-exchanger-%02d", i)]
        if hx then
            hx.energy_consumption = scale_energy(hx.name, "energy_consumption",
                hx.energy_consumption, mult) or hx.energy_consumption
            if base_hx.target_temperature and hx.target_temperature ~= base_hx.target_temperature then
                log(string.format("[patchwork/power-tier] %s: target_temperature %s -> %s (follow base)",
                    hx.name, tostring(hx.target_temperature), tostring(base_hx.target_temperature)))
                hx.target_temperature = base_hx.target_temperature
            end
        end
    end
end

local base_hx = data.raw["boiler"] and data.raw["boiler"]["heat-exchanger"]
local hc = base_hx and parse_energy(base_hx.energy_consumption)
local hx_mult = hc and hc / VANILLA_HEATEX_CONSUMPTION_W
local hx_t2 = data.raw["boiler"] and data.raw["boiler"]["5d-heat-exchanger-02"]

if not (hx_mult and math.abs(hx_mult - 1) > 1e-9) then
    log("[patchwork/power-tier] base heat-exchanger unchanged from vanilla, tiers left as-is")
elseif hx_t2 and tiers_still_vanilla("heat-exchanger", hx_mult,
        hx_t2.energy_consumption, base_hx.energy_consumption) then
    scale_heat_exchangers(hx_mult, base_hx)
end
