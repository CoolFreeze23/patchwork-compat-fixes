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

-- Vanilla values 5dim_energy 2.0.x derives its progression from
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

-- Solar panels ---------------------------------------------------------------

local base_solar = data.raw["solar-panel"]["solar-panel"]
local solar_mult = base_solar and base_multiplier(base_solar.production, VANILLA_SOLAR_PRODUCTION_W)

if solar_mult then
    for i = 2, 10 do
        local panel = data.raw["solar-panel"][string.format("5d-solar-panel-%02d", i)]
        if panel then
            panel.production = scale_stat(panel.name, "production", panel.production, solar_mult)
                or panel.production
        end
    end
else
    log("[patchwork/energy-tier] base solar-panel unchanged from vanilla, solar tiers left as-is")
end

-- Accumulators ---------------------------------------------------------------

local base_accu = data.raw["accumulator"]["accumulator"]
local base_accu_source = base_accu and base_accu.energy_source
local buffer_mult = base_accu_source and base_multiplier(base_accu_source.buffer_capacity, VANILLA_ACCU_BUFFER_J)
local input_mult = base_accu_source and base_multiplier(base_accu_source.input_flow_limit, VANILLA_ACCU_FLOW_W)
local output_mult = base_accu_source and base_multiplier(base_accu_source.output_flow_limit, VANILLA_ACCU_FLOW_W)

if buffer_mult or input_mult or output_mult then
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
else
    log("[patchwork/energy-tier] base accumulator unchanged from vanilla, accumulator tiers left as-is")
end
