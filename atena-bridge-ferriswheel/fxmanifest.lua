-- atena-bridge-ferriswheel — the ferriswheel <-> atena integration + PRESENTATION (bridge doctrine,
-- atena-framework §6; standalone-resource §2.1 headless). The ferriswheel standalone is headless:
-- this bridge OWNS the control panel (CEF), the [E] booth interaction, the boarding interaction and
-- the dev tooling, built on the standalone's read-only exports (exports['atena-std-ferriswheel']:*) + intents
-- (ferriswheel:op:* / :board / :alight). It also injects atena's authorizer + inbound guard.
-- A bridge is EXEMPT from the anti-bias rule: calling exports['atena-std-ferriswheel']:* / Atena.* is its nature.
-- Each file self-guards (GetResourceState) so it stays INERT unless its dependencies are started.

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'atena-bridge-ferriswheel'
author 'SirTheo'
description 'Bridge: ferriswheel <-> atena + presentation (control panel, booth, boarding, debug)'
version '0.1.0'

-- No escrow_ignore: a bridge is INTEGRATION GLUE (atena-framework §6), not a protected product. It ships
-- in cleartext WITH its standalone and is never escrowed/obfuscated/name-locked (escrow-protection rule).

shared_scripts {
    'shared/config.lua',        -- presentation tunables (booth [E] reach, draw/board ranges)
}

server_scripts {
    'server/auth.lua',          -- inject atena's authorizer + inbound-guard into ferriswheel
}

-- Presentation (framework side): the control panel, booth [E], boarding interaction, dev tooling.
client_scripts {
    'client/panel.lua',         -- [E] at the booth -> CEF control panel -> ferriswheel:op:* intents
    'client/boarding.lua',      -- detect walk-in/out of the platform gondola -> board/alight intents
    'client/debug.lua',         -- /ferriswheel tp|tpbooth|info dev commands (reads the exports)
}

-- The bespoke CEF control panel (presentation lives in the bridge, never in the standalone).
-- nui/ is the BUILT output of web/ (Vite + React + Tailwind — `npm run build` in web/). Hashed
-- asset names => recreate the dev container after a rebuild (txAdmin can't `refresh`).
ui_page 'nui/index.html'
files {
    'nui/index.html',
    'nui/assets/**',
}
