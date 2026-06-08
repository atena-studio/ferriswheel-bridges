-- atena-bridge-ferriswheel/client/panel.lua — the operator CONTROL PANEL (presentation, bridge-side).
--
-- The ferriswheel standalone is headless: it exposes read-only state (exports['std-ferriswheel']:getState /
-- boothPose) and accepts intents (ferriswheel:op:*). THIS bridge owns the presentation: the [E] booth
-- prompt + the CEF panel + forwarding the lever actions as intents. Inert without the standalone.

if GetResourceState('std-ferriswheel') ~= 'started' then return end

local OPEN_KEY = 38   -- INPUT_PICKUP (E)
local panelOpen = false
local boothPos, TW

-- Resolve the booth pose from the standalone once it's up (pure read-only export). The [E] REACH is
-- a presentation tunable owned by this bridge (Bridge.promptDist), not the standalone.
CreateThread(function()
    while not boothPos do
        local p, _, w = exports['std-ferriswheel']:boothPose()
        if p then boothPos, TW = p, w or 1 end
        if not boothPos then Wait(500) end
    end
end)

local function pushState()
    local s = exports['std-ferriswheel']:getState(TW or 1)
    if not s then return end
    s.action = 'state'
    SendNUIMessage(s)
end

local function openPanel()
    if panelOpen then return end
    panelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    pushState()
end

local function closePanel()
    if not panelOpen then return end
    panelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ---- NUI callbacks -> standalone intents ----------------------------------
RegisterNUICallback('run', function(data, cb)
    TriggerServerEvent('std-ferriswheel:op:run', data and data.run and true or false); cb('ok')
end)
RegisterNUICallback('step', function(_, cb) TriggerServerEvent('std-ferriswheel:op:step'); cb('ok') end)
RegisterNUICallback('estop', function(_, cb) TriggerServerEvent('std-ferriswheel:op:estop'); cb('ok') end)
RegisterNUICallback('callOperator', function(_, cb) TriggerServerEvent('std-ferriswheel:op:callOperator'); cb('ok') end)
RegisterNUICallback('dismissOperator', function(_, cb) TriggerServerEvent('std-ferriswheel:op:dismissOperator'); cb('ok') end)
RegisterNUICallback('close', function(_, cb) closePanel(); cb('ok') end)

-- Action refused by the standalone (proximity/mode/held) -> surface it on the panel.
RegisterNetEvent('std-ferriswheel:op:denied', function(reason)
    if panelOpen then SendNUIMessage({ action = 'toast', reason = tostring(reason) }) end
end)

-- ---- [E] booth zone (presentation: prompt + live state push) --------------
-- Prompt rendering: atena's shared TextUI pill when atena is up (one prompt language across the
-- server — show/hide ON-CHANGE, never per-frame), native draw as the standalone-only fallback.
local function drawPrompt(text)
    DrawRect(0.5, 0.90, 0.26, 0.065, 0, 0, 0, 150)
    SetTextFont(4); SetTextScale(0.45, 0.45); SetTextColour(120, 255, 120, 255)
    SetTextOutline(); SetTextCentre(true)
    BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.885)
end

local promptShown = false
-- returns true when atena owns the prompt (no per-frame draw needed); idempotent on-change push
local function setPrompt(on)
    if GetResourceState('atena') ~= 'started' then promptShown = false; return false end
    if on ~= promptShown then
        promptShown = on
        exports.atena:uiTextUI(on and { key = 'E', text = 'Quadro comandi giostra' } or false)
    end
    return true
end

CreateThread(function()
    local inside = false
    local pushAccum = 0
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local pc = (ped ~= 0) and GetEntityCoords(ped) or nil
        if boothPos and pc and #(pc - boothPos) < (Bridge.drawRange or 12.0) then
            sleep = 0
            local reach = Bridge.promptDist or 1.6
            local dx, dy = pc.x - boothPos.x, pc.y - boothPos.y
            local d2 = dx * dx + dy * dy
            if inside then inside = d2 <= (reach + 0.5) * (reach + 0.5) else inside = d2 <= reach * reach end
            if panelOpen then
                setPrompt(false)
                pushAccum = pushAccum + 1
                if pushAccum >= 5 then pushAccum = 0; pushState() end
            elseif inside then
                if not setPrompt(true) then drawPrompt('[E] quadro comandi giostra') end
                if IsControlJustPressed(0, OPEN_KEY) then openPanel() end
            else
                setPrompt(false)
            end
        else
            inside = false
            setPrompt(false)
            -- walked beyond the draw range with the desk open: close it (the push loop would
            -- otherwise stop and freeze the panel on stale state; the standalone denies far
            -- actions anyway — this just keeps the presentation honest).
            if panelOpen then closePanel() end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if panelOpen then SetNuiFocus(false, false) end
    setPrompt(false)   -- don't leave a stale atena TextUI pill behind
end)
