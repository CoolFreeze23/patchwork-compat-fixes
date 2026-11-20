-- Smart belt dragging (the 2.0 feature that auto-places underground belts when you
-- drag a belt line over an obstacle) only works when the transport belt declares its
-- partner via related_underground_belt. Ported belt mods often never set it (Advanced
-- Furnaces 2's pro belts). Pair every belt missing the field with its underground by
-- exact name convention (X-transport-belt-Y <-> X-underground-belt-Y), and only when
-- the speeds match exactly - never guess a wrong tunnel.
for name, belt in pairs(data.raw["transport-belt"] or {}) do
  if not belt.related_underground_belt then
    local candidate = name:gsub("transport%-belt", "underground-belt")
    if candidate ~= name then
      local ug = (data.raw["underground-belt"] or {})[candidate]
      if ug and ug.speed == belt.speed then
        belt.related_underground_belt = candidate
      end
    end
  end
end
