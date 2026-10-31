#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Clears debug players, groups, all rooms and all messages. Only compiled into
 * builds made with __A3_DEBUG__.
 *
 * TODO: the page is not told that its rooms disappeared; there is no
 * Room.Remove push in the protocol yet. A reconnect or RequestChatState shows
 * the cleared state.
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
{
    [_x, keys (_x get "participants")] call FUNC(serverBroadcastRoom);
} forEach (values GVAR(serverRooms));

GVAR(debugFakePlayers) = createHashMap;
GVAR(debugFakeGroups) = createHashMap;

GVAR(serverRooms) = createHashMap;
GVAR(serverRoomsByPlayer) = createHashMap;
GVAR(serverMessageCounter) = 0;
GVAR(serverRoomCounter) = 0;

[_sender] call FUNC(serverPushPlayerList);

createHashMapFromArray [["ok", true]]
#endif
