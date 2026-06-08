-- atena-bridge-ferriswheel/client/debug.lua — dev tooling (presentation/commands, bridge-side).
--
-- Headless standalone has no debug/commands; the tooling lives here in the bridge and consumes the
-- standalone's read-only exports (it exercises the REAL state, never a copy). Bridge MAY log.
--   /ferriswheel tpbooth   -> teleport to the control booth (ground-snapped)
--   /ferriswheel info      -> print the live ride state from exports['std-ferriswheel']:getState

if GetResourceState('std-ferriswheel') ~= 'started' then return end

RegisterCommand('ferriswheel', function(_, args)
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
        local _, _, w = exports['std-ferriswheel']:boothPose()
        local s = exports['std-ferriswheel']:getState(w or 1)
        if not s then print('[atena-bridge-ferriswheel] no state'); return end
        print(('[atena-bridge-ferriswheel] wheel %d: mode=%s present=%s running=%s spinning=%s held=%s angle=%.1f platformCar=%d riders=%d')
            :format(s.wheel, tostring(s.mode), tostring(s.operatorPresent), tostring(s.running),
                    tostring(s.spinning), tostring(s.held), s.angle, s.platformCar, s.riders))
    else
        print('[atena-bridge-ferriswheel] usage: /ferriswheel tpbooth | info')
    end
end, false)
