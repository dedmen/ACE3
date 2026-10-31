#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// Server-authoritative message database. Only the server maintains it; clients
// keep empty maps so the shared helpers never read a nil variable.
GVAR(serverRooms) = createHashMap; // room id -> room record
GVAR(serverRoomsByPlayer) = createHashMap; // player uid -> HashMap<room id, room record>
GVAR(serverPlayerClients) = createHashMap; // player uid -> HashMap<client id, visible>
GVAR(serverPlayerPresence) = createHashMap; // player uid -> "available" | "minimized" | "offline"
GVAR(serverMessageCounter) = 0;
GVAR(serverRoomCounter) = 0;

// Group id -> HashMap<roomId, true>. Groups invited into one or more rooms are
// tracked through UnitJoined / UnitLeft / Deleted handlers.
GVAR(groupRooms) = createHashMap;
// str(group) -> group id. Group variables are not reliable inside Deleted.
GVAR(groupObjectIds) = createHashMap;

// Persistence scaffolding is intentionally disabled: nothing saves or loads
// automatically. FUNC(serverSaveState) / FUNC(serverLoadState) only run when a
// debug command invokes them.
GVAR(serverPersistenceEnabled) = false;

// Page clients connected to this machine: the in-game phone "local" plus every
// WebSocket page client, mapped to the last reported visibility.
GVAR(webClients) = createHashMap;

#ifdef __A3_DEBUG__
// Debug-only fake players and groups (see fnc_debugAddFakePlayers).
GVAR(debugFakePlayers) = createHashMap;
GVAR(debugFakeGroups) = createHashMap;
GVAR(debugGroupUnits) = createHashMap; // synthetic uid -> AI unit
GVAR(debugAIGroups) = createHashMap; // group id -> AI-only group object
// GVAR(debugAllowEnemyChat) is only set by Messaging.Debug.SetAllowEnemyChat;
// until then the real CBA setting is used.
#endif

ADDON = true;
