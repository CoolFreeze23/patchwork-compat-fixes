-- Runtime (control-stage) fixes. Data-stage fixes live in fixes/ and are
-- loaded from data-final-fixes.lua; each control-fixes/ module registers its
-- own event handlers and no-ops when its target mod is absent.
-- NOTE: script.on_event replaces any earlier handler for the same event, so
-- if two modules ever need the same event, merge them into one dispatcher.
require("control-fixes.autodeconstruct-loader-chest")
