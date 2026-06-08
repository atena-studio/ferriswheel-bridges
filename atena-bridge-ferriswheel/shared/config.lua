-- atena-bridge-ferriswheel/shared/config.lua — PRESENTATION tunables (bridge-owned).
--
-- Per standalone-resource §2.1: presentation tunables (keys, reach, draw radii, labels) live in the
-- BRIDGE config, never in the standalone (which keeps only gameplay tunables). The standalone exposes
-- the booth POSE + state; the bridge decides how the player interacts with it.

Bridge = Bridge or {}

Bridge.promptDist = 1.6    -- [E] reach (m) around the control booth to open the panel
Bridge.drawRange  = 12.0   -- only draw the booth prompt within this range (perf)
Bridge.boardRange = 40.0   -- boarding-detection away-gate (m): run the walk-in/out test only this near
