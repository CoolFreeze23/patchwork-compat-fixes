-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["5dim-sniper-range-fix"] then return end

-- Some mods (Krastorio 2) turn bullet ammo into real projectiles with a max_range
-- tuned for their own turrets (30 tiles). Long-ranged turrets from other mods
-- (5Dim sniper turrets reach 79 tiles) then target and shoot things their bullets
-- can never reach. Fix: per ammo category, find the longest turret attack range and
-- make sure every projectile delivery of that category can fly at least that far.

local MARGIN = 2

-- longest attack range per ammo category over all ammo turrets
local maxRangeByCategory = {}
for _, turret in pairs(data.raw["ammo-turret"] or {}) do
    local ap = turret.attack_parameters
    if ap and ap.range then
        local categories = ap.ammo_categories or { ap.ammo_category }
        for _, category in pairs(categories) do
            if maxRangeByCategory[category] == nil or ap.range > maxRangeByCategory[category] then
                maxRangeByCategory[category] = ap.range
            end
        end
    end
end

-- recursively raise max_range of projectile action deliveries below the target range
local function raiseMaxRange(node, target)
    if type(node) ~= "table" then return end
    if node.type == "projectile" and node.projectile ~= nil
        and node.max_range ~= nil and node.max_range < target then
        node.max_range = target
    end
    for _, child in pairs(node) do
        raiseMaxRange(child, target)
    end
end

for _, ammo in pairs(data.raw.ammo or {}) do
    local category = ammo.ammo_category
    -- pre-2.0 style ammo_type.category still appears in some mods; tolerate it
    if category == nil and type(ammo.ammo_type) == "table" then
        category = ammo.ammo_type.category
    end

    local target = category and maxRangeByCategory[category]
    if target and ammo.ammo_type then
        raiseMaxRange(ammo.ammo_type, target + MARGIN)
    end
end
