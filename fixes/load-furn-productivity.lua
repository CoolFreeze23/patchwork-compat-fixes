-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["load-furn-prod-fix"] then return end

-- Load-Furn 2 predates Factorio 2.0's per-recipe productivity flag; its generated
-- recipes never set allow_productivity, so prod modules are rejected with the legacy
-- "Only intermediate products" message. "cool" is the wood->coal recipe.
for _, name in pairs({ "cool", "steel-plate2" }) do
  local recipe = data.raw.recipe[name]
  if recipe then
    recipe.allow_productivity = true
  end
end
