#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Exercises the disabled persistence scaffolding by loading and importing stored
 * server state. Only compiled into builds made with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Request <HASHMAP>
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMap, player] call ace_tacphone_Messaging_fnc_debugLoadState
 *
 * Public: No
 */

params ["_request", "_sender"];

if (!isServer) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Not the server"]]
};

private _state = [] call FUNC(serverLoadState);

if (count _state == 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No stored state"]]
};

[_state] call FUNC(serverImportState);

[_sender] call FUNC(serverPushPlayerList);

createHashMapFromArray [
    ["ok", true],
    ["rooms", count (keys GVAR(serverRooms))]
]
#endif
