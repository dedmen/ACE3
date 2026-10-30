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

// Remote access identity (JSON { "hostId": "...", "secret": "..." }) and the last
// status returned by the extension. Persisted in profileNamespace.
GVAR(remoteIdentity) = "";
GVAR(remoteState) = createHashMap;

// Extension diagnostics that could not be delivered to the page yet (and are
// replayed once the in-game browser asks with "GetHostLog"). Capped to 50.
GVAR(hostLog) = [];

// Just a dummy for our request dispatch logic
GVAR(AppInfo) set ["main", createHashMapFromArray [
    ["requestprocessor", FUNC(processBrowserRequest)]
]];



ADDON = true;
