-- atena-bridge-ferriswheel/client/boarding.lua — the BOARDING INTERACTION (presentation/detection, bridge-side).
--
-- Headless standalone: it RENDERS seated riders (pins them) and owns the seating state, but it does NOT
-- detect boarding. THIS bridge does the walk-in / walk-out detection against the platform gondola
-- (using exports['atena-std-ferriswheel']:getState / carEntity / insideGondola) and fires the intents
-- (ferriswheel:board / ferriswheel:alight). The standalone validates + books + publishes the seat.

if GetResourceState('atena-std-ferriswheel') ~= 'started' then return end

local lastIntent = 0

CreateThread(function()
    local TW = 1
    local boothPos
    -- booth pose gives us the wheel index + a cheap away-gate anchor
    while not boothPos do
        local p, _, w = exports['atena-std-ferriswheel']:boothPose()
        if p then boothPos, TW = p, w or 1 end
        if not boothPos then Wait(500) end
    end

    while true do
        local sleep = 250
        local ped = PlayerPedId()
        local pos = (ped ~= 0) and GetEntityCoords(ped) or nil
        -- Away-gate: only run the per-frame proximity test near the wheel.
        if pos and boothPos and #(pos - boothPos) < (Bridge.boardRange or 40.0) then
            local s = exports['atena-std-ferriswheel']:getState(TW)
            local mySeat = LocalPlayer.state.ferriswheelCar   -- set by the standalone server when booked
            local now = GetGameTimer()
            if s and s.boardable then
                sleep = 0
                if not mySeat then
                    -- walk INTO the platform gondola -> book a seat
                    local car = s.platformCar
                    if car and exports['atena-std-ferriswheel']:insideGondola(TW, car, pos.x, pos.y, pos.z)
                       and (now - lastIntent) > 400 then
                        lastIntent = now
                        TriggerServerEvent('atena-std-ferriswheel:board', TW)
                    end
                elseif s.platformCar == mySeat.car then
                    -- our gondola is back at the platform, stopped: walk OUT -> release the seat
                    if not exports['atena-std-ferriswheel']:insideGondola(TW, mySeat.car, pos.x, pos.y, pos.z)
                       and (now - lastIntent) > 400 then
                        lastIntent = now
                        TriggerServerEvent('atena-std-ferriswheel:alight')
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
