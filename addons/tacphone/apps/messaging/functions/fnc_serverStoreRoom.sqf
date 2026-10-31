#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Stores a room record in the global room map and in every participant's map.
 * The exact same record hashmap (and therefore the same messages array) is
 * stored everywhere, so a new message is visible to every participant without
 * copying.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record] call ace_tacphone_Messaging_fnc_serverStoreRoom
 *
 * Public: No
 */

params ["_record"];

private _roomId = _record get "id";

GVAR(serverRooms) set [_roomId, _record];

{
    private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefaultCall [_x, {createHashMap}, true];
    _playerRooms set [_roomId, _record];
} forEach (keys (_record get "participants"));
