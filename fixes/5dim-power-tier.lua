-- Defer to a standalone fix mod if one is installed.
if mods["5dim-power-tier-fix"] then return end

-- 5dim_energy's nuclear reactor and heat exchanger tiers derive from vanilla
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

-- Nuclear reactors ------------------------------------------------------------

local base_reactor = data.raw["reactor"] and data.raw["reactor"]["nuclear-reactor"]
local rc = base_reactor and parse_energy(base_reactor.consumption)
local cons_mult = rc and rc / VANILLA_REACTOR_CONSUMPTION_W
local bonus_mult = base_reactor and
    ((base_reactor.neighbour_bonus or 1) / VANILLA_REACTOR_NEIGHBOUR_BONUS)
if cons_mult and math.abs(cons_mult - 1) > 1e-9 then
    for i = 2, 10 do
        local r = data.raw["reactor"][string.format("5d-nuclear-reactor-%02d", i)]
        if r then
            r.consumption = scale_energy(r.name, "consumption", r.consumption, cons_mult)
                or r.consumption
            if bonus_mult and math.abs(bonus_mult - 1) > 1e-9 then
                local old = r.neighbour_bonus or 1
                r.neighbour_bonus = old * bonus_mult
                log(string.format("[patchwork/power-tier] %s: neighbour_bonus %s -> %s (x%.4g)",
                    r.name, tostring(old), tostring(r.neighbour_bonus), bonus_mult))
            end
        end
    end
else
    log("[patchwork/power-tier] base nuclear-reactor unchanged from vanilla, tiers left as-is")
end

-- Heat exchangers --------------------------------------------------------------

local base_hx = data.raw["boiler"] and data.raw["boiler"]["heat-exchanger"]
local hc = base_hx and parse_energy(base_hx.energy_consumption)
local hx_mult = hc and hc / VANILLA_HEATEX_CONSUMPTION_W
if hx_mult and math.abs(hx_mult - 1) > 1e-9 then
    for i = 2, 10 do
        local hx = data.raw["boiler"][string.format("5d-heat-exchanger-%02d", i)]
        if hx then
            hx.energy_consumption = scale_energy(hx.name, "energy_consumption",
                hx.energy_consumption, hx_mult) or hx.energy_consumption
            if base_hx.target_temperature and hx.target_temperature ~= base_hx.target_temperature then
                log(string.format("[patchwork/power-tier] %s: target_temperature %s -> %s (follow base)",
                    hx.name, tostring(hx.target_temperature), tostring(base_hx.target_temperature)))
                hx.target_temperature = base_hx.target_temperature
            end
        end
    end
else
    log("[patchwork/power-tier] base heat-exchanger unchanged from vanilla, tiers left as-is")
end
