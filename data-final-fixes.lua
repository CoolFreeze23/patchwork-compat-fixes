-- Patchwork: self-contained cross-mod compatibility fixes.
-- Design rules:
--   * every module no-ops cleanly when its target mods/prototypes are absent
--   * every module defers to its original standalone fix mod when that is installed
--   * ordering: this pack sorts AFTER all touched mods via optional dependencies.
--     (5dim-mini-mining-fix intentionally stays a separate mod: it must sort BEFORE
--     mini-machines' data-final-fixes, while the furnace fix must sort after - one
--     mod cannot occupy both positions in the load order.)
require("fixes.5dim-lab-science")
require("fixes.5dim-furnace-smelting")
require("fixes.5dim-sniper-range")
require("fixes.5dim-energy-tier")
require("fixes.5dim-train-tier")
require("fixes.5dim-belt-tier")
require("fixes.5dim-turret-tier")
require("fixes.5dim-power-tier")
require("fixes.hovercraft-fuel")
require("fixes.spidertron-grid")
require("fixes.load-furn-productivity")
require("fixes.loader-upgrade")
require("fixes.loader-circuit")
require("fixes.belt-underground-drag")
