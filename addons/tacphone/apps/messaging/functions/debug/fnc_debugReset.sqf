#include "..\..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Clears debug players, groups, all rooms and all messages. Only compiled into
 * builds made with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Request <HASHMAP>
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMap, player] call ace_tacphone_Messaging_fnc_debugReset
 *
 * Public: No
 */

params ["_request", "_sender"];

REQUIRE_SENDER(_sender);

{
    if (!isNull _y) then {
        deleteVehicle _y;
    };
} forEach GVAR(debugGroupUnits);
GVAR(debugGroupUnits) = createHashMap;

{
    if (!isNull _y) then {
        deleteGroup _y;
    };
} forEach GVAR(debugAIGroups);
GVAR(debugAIGroups) = createHashMap;

{
    GVAR(serverPlayerPresence) deleteAt _x;
} forEach (keys GVAR(debugFakePlayers));

// Tell open pages that their rooms are gone; debug reset deletes the server
// database, so a page would otherwise keep stale conversations until a reload.
// Only the removed push goes out: a full upsert first would resurrect each
// room for a frame before its removal lands. The page drops the room by id,
// so the payload needs no more.
{
    private _push = createHashMapFromArray [
        ["a", MESSAGING_APP],
        ["c", "Room.Upsert"],
        ["room", createHashMapFromArray [["id", _x get "id"]]],
        ["removed", true]
    ];

    [keys (_x get "participants"), _push] call FUNC(serverPushToUids);
} forEach (values GVAR(serverRooms));

// Untrack every group before the records are dropped: removes the group's
// event handlers and variables and clears the tracking maps.
{
    private _record = _x;

    {
        [_record, _groupId] call FUNC(serverUntrackGroup);
    } forEach (keys (_record getOrDefault ["groups", createHashMap]));
} forEach (values GVAR(serverRooms));

GVAR(debugFakePlayers) = createHashMap;
GVAR(debugFakeGroups) = createHashMap;

GVAR(serverRooms) = createHashMap;
GVAR(serverRoomsByPlayer) = createHashMap;
GVAR(groupRooms) = createHashMap;
GVAR(groupObjectIds) = createHashMap;
GVAR(serverMessageCounter) = 0;
GVAR(serverRoomCounter) = 0;

[_sender] call FUNC(serverPushPlayerList);

createHashMapFromArray [["ok", true]]
#endif
