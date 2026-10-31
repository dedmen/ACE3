#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Rebuilds room records from serialized state and re-establishes the shared
 * array/record references between player maps. Persistence is disabled; this
 * only runs when called explicitly (for example by the debug commands).
 *
 * Arguments:
 * 0: Serialized state <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[true] call ace_tacphone_Messaging_fnc_serverExportState] call ace_tacphone_Messaging_fnc_serverImportState
 *
 * Public: No
 */

params ["_state"];

if (!(_state isEqualType createHashMap)) exitWith {};
if (count _state == 0) exitWith {};

GVAR(serverRooms) = createHashMap;
GVAR(serverRoomsByPlayer) = createHashMap;
GVAR(serverMessageCounter) = _state getOrDefault ["messageCounter", 0];
GVAR(serverRoomCounter) = _state getOrDefault ["roomCounter", 0];

{
    private _data = _x;
    private _participantMap = createHashMap;

    {
        _participantMap set [_x select 0, _x select 1];
    } forEach (_data getOrDefault ["participants", []]);

    private _record = createHashMapFromArray [
        ["id", _data get "id"],
        ["kind", _data getOrDefault ["kind", "group"]],
        ["name", _data getOrDefault ["name", ""]],
        ["participants", _participantMap],
        ["groups", createHashMap],
        ["messages", _data getOrDefault ["messages", []]],
        ["createdAt", _data getOrDefault ["createdAt", 0]],
        ["createdBy", _data getOrDefault ["createdBy", ""]],
        ["inviteKey", _data getOrDefault ["inviteKey", ""]]
    ];

    GVAR(serverRooms) set [_record get "id", _record];

    {
        private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefaultCall [_x, {createHashMap}, true];
        _playerRooms set [_record get "id", _record];
    } forEach (keys _participantMap);
} forEach (_state getOrDefault ["rooms", []]);
