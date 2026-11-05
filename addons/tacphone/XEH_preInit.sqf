#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

GVAR(AppInfo) = createHashMap; // Stores list of all apps, and information on how to load them and where to pass requests to

// Information interests held by connected web clients (demand driven game -> web updates)
// key: interest name (String) -> HashMap ["clients" -> HashMap (clientId -> true), "active" -> Bool]
GVAR(AppDataInterests) = createHashMap;

// Opaque remote access identity JSON. Stored in profileNamespace by the web UI
// through RemoteAccess.Get/SetAuthIdentity; SQF never parses it.
GVAR(remoteIdentity) = "";
GVAR(remoteState) = createHashMap;

// Extension diagnostics that could not be delivered to the page yet (and are
// replayed once the in-game browser asks with "GetHostLog"). Capped to 50.
GVAR(hostLog) = [];

// Native relay WebSocket state. The handle is local to this machine; handles are
// not serializable and are null after loading a savegame. `isNull` is not
// reliable on a webRequest promise handle, so use a string sentinel instead.
localNamespace setVariable [QGVAR(relayHandle), "gone"];
GVAR(relayArmed) = false;
GVAR(relayGeneration) = 0;
GVAR(relayUrl) = "";
GVAR(relayWebBase) = "";

// Just a dummy for our request dispatch logic
GVAR(AppInfo) set ["main", createHashMapFromArray [
    ["requestprocessor", FUNC(processBrowserRequest)]
]];



ADDON = true;
