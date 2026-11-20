-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["5dim-energy-tier-fix"] then return end

-- 5dim_energy generates its tiers at data stage by copying the vanilla
-- prototypes and writing absolute stats derived from vanilla's values:
--   solar panel: production 60kW + 30kW per tier
--   accumulator: buffer 5MJ + 2.5MJ per tier, flow 300kW + 150kW per tier
-- Mods that rebalance the BASE entities afterwards (Krastorio 2 data-updates
-- sets solar-panel to 100kW and accumulator to 10MJ/600kW) don't touch the
-- 5Dim copies, so low 5Dim tiers end up weaker than the tier-1 base entity.
--
-- Fix: compute how much each base stat was changed relative to the vanilla
-- value the 5Dim progression was built from, and rescale every 5Dim tier by
-- that same factor. Each tier keeps its intended percentage over tier 1
-- regardless of which mod (or combination) rebalanced the base entity.

-- Vanilla values 5dim_energy derives its progression from (2.1.x: hardcoded
-- basePower 60kW / 5MJ / 300kW with a x1.45-per-tier curve)
local VANILLA_SOLAR_PRODUCTION_W = 60e3 -- 60kW
local VANILLA_ACCU_BUFFER_J = 5e6 -- 5MJ
local VANILLA_ACCU_FLOW_W = 300e3 -- 300kW

local SI_PREFIX = { k = 1e3, K = 1e3, M = 1e6, G = 1e9, T = 1e12, P = 1e15 }

-- "150kW" -> 150000, "W"; returns nil for anything it can't parse
local function parse_energy(value)
    if type(value) ~= "string" then return nil end
    local num, prefix, unit = value:match("^(%d+%.?%d*)([kKMGTP]?)([WJ])$")
    if not num then return nil end
    return tonumber(num) * (SI_PREFIX[prefix] or 1), unit
end

local function base_multiplier(current_value, vanilla_number)
    local current = parse_energy(current_value)
    if not current or current <= 0 then return nil end
    local mult = current / vanilla_number
    if math.abs(mult - 1) < 1e-9 then return nil end
    return mult
end

local function scale_stat(entity_name, field_desc, value, mult)
    local n, unit = parse_energy(value)
    if not n then
        log("[patchwork/energy-tier] " .. entity_name .. ": cannot parse " ..
            field_desc .. " '" .. tostring(value) .. "', skipped")
        return nil
    end
    local new_value = string.format("%.0f", n * mult) .. unit
    log(string.format("[patchwork/energy-tier] %s: %s %s -> %s (x%.4g)",
        entity_name, field_desc, tostring(value), new_value, mult))
    return new_value
end

-- Double-scale guard: 5Dim derives its tiers from hardcoded vanilla numbers,
-- so a tier-2 value still BELOW a raised base value proves the tiers were not
-- rebalanced by anyone. If tier 2 already reaches the base value, 5Dim (or
-- another mod) already follows the rebalanced base and rescaling again would
-- double-scale - leave the family alone. Only raised stats (mult > 1) can be
-- told apart this way; a family whose stats were only lowered is left as-is.
local function tiers_still_vanilla(family, checks)
    local raised = 0
    for _, c in ipairs(checks) do
        if c.mult and c.mult > 1 then
            raised = raised + 1
            local tier2, base = parse_energy(c.tier2), parse_energy(c.base)
            if not (tier2 and base and tier2 < base) then
                log("[patchwork/energy-tier] " .. family .. ": tier 2 " .. c.field .. " " ..
                    tostring(c.tier2) .. " already reaches the base " .. tostring(c.base) ..
                    " - tiers already follow the base, left as-is")
                return false
            end
        end
    end
    if raised == 0 then
        log("[patchwork/energy-tier] " .. family .. ": base stats were only lowered, tiers left as-is")
        return false
    end
    return true
end

-- Solar panels ---------------------------------------------------------------

local base_solar = data.raw["solar-panel"]["solar-panel"]
local solar_mult = base_solar and base_multiplier(base_solar.production, VANILLA_SOLAR_PRODUCTION_W)

local solar_t2 = data.raw["solar-panel"]["5d-solar-panel-02"]

if solar_mult and solar_t2 and tiers_still_vanilla("solar", {
    { field = "production", mult = solar_mult, tier2 = solar_t2.production, base = base_solar.production },
}) then
    for i = 2, 10 do
        local panel = data.raw["solar-panel"][string.format("5d-solar-panel-%02d", i)]
        if panel then
            panel.production = scale_stat(panel.name, "production", panel.production, solar_mult)
                or panel.production
        end
    end
elseif not solar_mult then
    log("[patchwork/energy-tier] base solar-panel unchanged from vanilla, solar tiers left as-is")
end

-- Accumulators ---------------------------------------------------------------

local base_accu = data.raw["accumulator"]["accumulator"]
local base_accu_source = base_accu and base_accu.energy_source
local buffer_mult = base_accu_source and base_multiplier(base_accu_source.buffer_capacity, VANILLA_ACCU_BUFFER_J)
local input_mult = base_accu_source and base_multiplier(base_accu_source.input_flow_limit, VANILLA_ACCU_FLOW_W)
local output_mult = base_accu_source and base_multiplier(base_accu_source.output_flow_limit, VANILLA_ACCU_FLOW_W)

local accu_t2 = data.raw["accumulator"]["5d-accumulator-02"]
local accu_t2_source = accu_t2 and accu_t2.energy_source

if (buffer_mult or input_mult or output_mult) and accu_t2_source and tiers_still_vanilla("accumulator", {
    { field = "buffer_capacity", mult = buffer_mult, tier2 = accu_t2_source.buffer_capacity, base = base_accu_source.buffer_capacity },
    { field = "input_flow_limit", mult = input_mult, tier2 = accu_t2_source.input_flow_limit, base = base_accu_source.input_flow_limit },
    { field = "output_flow_limit", mult = output_mult, tier2 = accu_t2_source.output_flow_limit, base = base_accu_source.output_flow_limit },
}) then
    for i = 2, 10 do
        local accu = data.raw["accumulator"][string.format("5d-accumulator-%02d", i)]
        if accu and accu.energy_source then
            local source = accu.energy_source
            if buffer_mult then
                source.buffer_capacity = scale_stat(accu.name, "buffer_capacity", source.buffer_capacity, buffer_mult)
                    or source.buffer_capacity
            end
            if input_mult then
                source.input_flow_limit = scale_stat(accu.name, "input_flow_limit", source.input_flow_limit, input_mult)
                    or source.input_flow_limit
            end
            if output_mult then
                source.output_flow_limit = scale_stat(accu.name, "output_flow_limit", source.output_flow_limit, output_mult)
                    or source.output_flow_limit
            end
        end
    end
elseif not (buffer_mult or input_mult or output_mult) then
    log("[patchwork/energy-tier] base accumulator unchanged from vanilla, accumulator tiers left as-is")
end
