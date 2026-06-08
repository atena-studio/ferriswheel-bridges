# atena-bridges-ferriswheel

Integration bridges for the `atena-std-ferriswheel` standalone resource, one per framework.

| Framework | Bridge | Status |
|-----------|--------|--------|
| atena     | `atena-bridge-ferriswheel` | present |
| ESX       | `esx-bridge-ferriswheel`   | planned |
| QBCore    | `qbcore-bridge-ferriswheel`| planned |
| OX        | `ox-bridge-ferriswheel`    | planned |

Each bridge is integration glue (calls `exports['atena-std-ferriswheel']:*` + the framework's API). The standalone
stays pure/agnostic; the bridge does the wiring. Advanced atena-only mechanics that a framework can't map
are left as a documented comment in that framework's bridge.

Install the standalone (`atena-std-ferriswheel`) + the ONE bridge matching your framework.
