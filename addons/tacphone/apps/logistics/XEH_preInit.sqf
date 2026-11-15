#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// Server-authoritative logistics queue. Only the server maintains these
// variables; clients keep empty placeholders so shared code never reads a nil
// variable. Every player sees the same queue, and the worker set is known to
// the server so workers can be auto-joined into the request rooms.
GVAR(serverRequests) = createHashMap; // request id -> request record
GVAR(serverRequestCounter) = 0; // request ids are "L-" + counter
GVAR(serverRoles) = createHashMap; // uid -> "worker"; absent = "player"

ADDON = true;
