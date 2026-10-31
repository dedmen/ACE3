#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Deletes one room from the server maps and tells every participant (including
 * already removed ones) that it is gone.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 * 1: Removed PlayerUIDs <ARRAY of STRING> (optional)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record, [_uid]] call ace_tacphone_Messaging_fnc_serverDeleteRoom
 *
 * Public: No
 */

params ["_record", ["_removedUids", []]];

private _roomId = _record get "id";

[_record, _removedUids] call FUNC(serverBroadcastRoom);

GVAR(serverRooms) deleteAt _roomId;

{
    [_record, _x] call FUNC(serverUntrackGroup);
} forEach (keys (_record getOrDefault ["groups", createHashMap]));
