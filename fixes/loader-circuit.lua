-- Defer to the standalone fix mod if it is still installed (prevents double
-- application; all fixes here are otherwise idempotent-safe on their own).
if mods["loader-circuit-fix"] then return end

-- Factorio 2.0 loaders support circuit connections natively; a prototype only needs
-- circuit_wire_max_distance > 0. K2's loaders prove a connector sprite is optional
-- (wires attach to the entity center). Grant connectivity to every loader missing it.
for _, typ in pairs({ "loader-1x1", "loader" }) do
  for _, proto in pairs(data.raw[typ] or {}) do
    if not proto.circuit_wire_max_distance or proto.circuit_wire_max_distance == 0 then
      proto.circuit_wire_max_distance = 9
    end
  end
end
