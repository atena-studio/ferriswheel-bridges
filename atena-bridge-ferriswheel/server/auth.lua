-- atena-bridge-ferriswheel — framework SEAMS (authorization + inbound guard). STUB.
-- Stays INERT unless both atena and ferriswheel are started. Once the ferriswheel standalone exposes
-- the seams (exports['std-ferriswheel']:setAuthorizer / setGuard — standalone-resource §6/§7), this installs
-- atena's policy: who may run privileged actions, and the centralized inbound guard.
if GetResourceState('atena') ~= 'started' or GetResourceState('std-ferriswheel') ~= 'started' then return end

-- Authorization: atena decides who can (deny-by-default privileged via Perms).
if exports['std-ferriswheel'] and exports['std-ferriswheel'].setAuthorizer then
    exports['std-ferriswheel']:setAuthorizer(function(src, action)
        return exports.atena:can(src, 'ferriswheel.' .. action)
    end)
end

-- Inbound guard: atena's centralized rate/schema/bounds/proximity validation.
if exports['std-ferriswheel'] and exports['std-ferriswheel'].setGuard then
    exports['std-ferriswheel']:setGuard(function(opts, src, args)
        return exports.atena:checkInbound(opts, src, args)
    end)
end
