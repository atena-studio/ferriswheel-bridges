-- atena-bridge-ferriswheel/client/debug.lua — dev tooling (presentation/commands, bridge-side).
--
-- Headless standalone has no debug/UI; the tooling lives here in the bridge and consumes the
-- standalone's read-only exports (it exercises the REAL state, never a copy). Two surfaces:
--   • F7 window manager: a live WHEEL inspector card (group 'ferriswheel'), hover-previewable.
--   • commands: /ferriswheel tpbooth (TP to booth) · /ferriswheel info (print live state).
-- ROBUST registration: no permanent load-time bail; thread one-shot + events (the entries reliably
-- (re)appear at boot, on load-order race, and after `restart atena`). atena-window-manager.md /
-- bridge-registration.md / atena-framework.md §6.

local WIN = 'ferriswheel:wheel'
local function atenaUp() return GetResourceState('atena') == 'started' end
local function wheelUp() return GetResourceState('std-ferriswheel') == 'started' end
local open, peeking = false, false

-- the wheel the booth belongs to (single-wheel today, but getState is per-wheel)
local function curWheel() local _, _, w = exports['std-ferriswheel']:boothPose(); return w or 1 end

-- live inspector rows read straight from the standalone's getState (headless: bridge renders, never decides)
local function rows()
    if not wheelUp() then return { { key = 'wheel', value = 'std-ferriswheel down', tone = 'warn' } } end
    local s = exports['std-ferriswheel']:getState(curWheel())
    if not s then return { { key = 'wheel', value = 'no state', tone = 'dim' } } end
    local function b(k, v) return { key = k, value = v and true or false, kind = 'value', tone = v and 'green' or 'dim' } end
    return {
        { key = 'wheel', value = ('%d / %d'):format(s.wheel or 1, s.count or 1), tone = 'accent' },
        { key = 'mode', value = tostring(s.mode), tone = 'accent' },
        b('operator', s.operatorPresent), b('running', s.running), b('spinning', s.spinning), b('held', s.held),
        { key = 'platform °', value = ('%.1f'):format(s.platformDeg or 0.0) },
        { key = 'deg/s', value = ('%.1f'):format(s.degPerSec or 0.0) },
        { key = 'platform car', value = ('%d / %d'):format(s.platformCar or 0, s.carCount or 0) },
        { key = 'riders', value = tostring(s.riders or 0) },
        b('boardable', s.boardable),
    }
end

local function pushCard() if atenaUp() then exports.atena:uiDebugPanel(WIN, { title = 'FERRISWHEEL · WHEEL', rows = rows() }) end end

-- registration (robust: thread one-shot for the first register + events for atena restarts)
local function reg() if atenaUp() then exports.atena:debugAdd({ id = WIN, group = 'ferriswheel', label = 'Wheel', icon = 'gauge', toggle = true, value = open, peekWin = WIN }) end end
local function badge() if atenaUp() then exports.atena:debugSet(WIN, open) end end
CreateThread(function() while not atenaUp() do Wait(250) end; reg() end)
AddEventHandler('onResourceStart', function(res) if res == 'atena' then reg() end end)
AddEventHandler('atena:debug:ready', reg)
AddEventHandler('atena:debug:refresh', reg)

AddEventHandler('atena:debug:invoke', function(id)
    if id ~= WIN then return end
    open = not open
    if open then exports.atena:uiDebugArrange(true); pushCard() else exports.atena:uiDebugPanel(WIN, nil) end
    badge()
end)
AddEventHandler('atena:debug:panelClosed', function(id)
    if id == WIN and open then open = false; exports.atena:uiDebugPanel(WIN, nil); badge() end
end)
-- hover-PEEK (ephemeral): render the card WITHOUT opening it for real (no open flag, no badge)
AddEventHandler('atena:debug:peek', function(win)
    if win == WIN and not open and atenaUp() then peeking = true; pushCard() end
end)
AddEventHandler('atena:debug:peekEnd', function(win)
    if win == WIN and not open and peeking then peeking = false; if atenaUp() then exports.atena:uiDebugPanel(WIN, nil) end end
end)
-- live refresh while the card is open or previewed (throttled; the data moves while spinning)
CreateThread(function() while true do if (open or peeking) and atenaUp() then pushCard() end; Wait(300) end end)

-- ── dev commands (kept): gate at CALL time (no permanent load bail) ───────────────────────────────
RegisterCommand('ferriswheel', function(_, args)
    if not wheelUp() then print('[atena-bridge-ferriswheel] std-ferriswheel not started'); return end
    local action = args[1]
    if action == 'tpbooth' then
        local p = exports['std-ferriswheel']:boothPose()
        if not p then print('[atena-bridge-ferriswheel] booth pose not available'); return end
        CreateThread(function()
            local ped = PlayerPedId()
            SetEntityCoordsNoOffset(ped, p.x, p.y, p.z + 20.0, false, false, false)
            RequestCollisionAtCoord(p.x, p.y, p.z)
            local tries = 0
            while not HasCollisionLoadedAroundEntity(ped) and tries < 100 do Wait(10); tries = tries + 1 end
            local ok, groundZ = GetGroundZFor_3dCoord(p.x, p.y, p.z + 20.0, 0.0, false)
            local z = ok and (groundZ + 1.0) or (p.z + 1.0)
            SetEntityCoordsNoOffset(ped, p.x, p.y, z, false, false, false)
            print(('[atena-bridge-ferriswheel] tp -> booth (%.1f, %.1f, %.1f)'):format(p.x, p.y, z))
        end)
    elseif action == 'info' then
        local s = exports['std-ferriswheel']:getState(curWheel())
        if not s then print('[atena-bridge-ferriswheel] no state'); return end
        print(('[atena-bridge-ferriswheel] wheel %d: mode=%s present=%s running=%s spinning=%s held=%s platform=%.1f car=%d riders=%d')
            :format(s.wheel, tostring(s.mode), tostring(s.operatorPresent), tostring(s.running),
                    tostring(s.spinning), tostring(s.held), s.platformDeg or 0.0, s.platformCar or 0, s.riders or 0))
    else
        print('[atena-bridge-ferriswheel] usage: /ferriswheel tpbooth | info')
    end
end, false)
