#include "..\..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Debug-only: clears the queue, the role map and the id counter, then pushes
 * the empty Logistics.State snapshot. The snapshot replaces every page's
 * queue wholesale (LogisticsModule.applyState), so no per-request
 * Logistics.Request.Remove is sent. Each request's Messenger room is deleted
 * first, so a reset leaves no "Logistics <id>" rooms behind — the id counter
 * restarts at zero and would otherwise create a second room with the same
 * name.
 *
 * Arguments:
 * 0: Request <HASHMAP>
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMap, player] call ace_tacphone_Logistics_fnc_debugReset
 *
 * Public: No
 */

params ["_request", "_sender"];

if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
    createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]]
};

REQUIRE_SENDER(_sender);

// Delete every request's Messenger room before the state is cleared. The
// isNil guard keeps a Logistics-only dev setup working without the Messaging
// app; a record without a room (roomId "") is skipped.
if (!isNil "ace_tacphone_Messaging_fnc_serverDeleteRoom") then {
    {
        private _roomId = _x getOrDefault ["roomId", ""];

        if (_roomId != "") then {
            private _roomRecord = ace_tacphone_Messaging_serverRooms getOrDefault [_roomId, createHashMap];

            if (count _roomRecord > 0) then {
                [_roomRecord] call ace_tacphone_Messaging_fnc_serverDeleteRoom;
            };
        };
    } forEach (values GVAR(serverRequests));
};

GVAR(serverRequests) = createHashMap;
GVAR(serverRoles) = createHashMap;
GVAR(serverRequestCounter) = 0;

[] call FUNC(serverPushState);

createHashMapFromArray [["ok", true]]
#endif
