#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Debug-only room snapshot, pushed back to the requesting test client. Used to
 * observe AI-only rooms that have no real page client.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "roomId": "" })
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["roomId", "grp:1_2"]], player] call ace_tacphone_Messaging_fnc_debugRoomInfo
 *
 * Public: No
 */

params ["_request", "_sender", ["_clientId", ""]];

if (isNull _sender) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _roomId = _request getOrDefault ["roomId", ""];
private _record = GVAR(serverRooms) getOrDefault [_roomId, createHashMap];
private _exists = count _record > 0;
private _participants = [];
private _groups = [];

if (_exists) then {
    {
        private _info = _y;
        _participants pushBack [
            _x,
            _info getOrDefault ["name", ""],
            _info getOrDefault ["groupId", ""],
            _info getOrDefault ["groupControlled", false]
        ];
    } forEach (_record get "participants");

    _groups = keys (_record getOrDefault ["groups", createHashMap]);
};

[_sender, createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "Debug.RoomInfo"],
    ["roomId", _roomId],
    ["exists", _exists],
    ["kind", _record getOrDefault ["kind", ""]],
    ["participants", _participants],
    ["groups", _groups]
], _clientId] call FUNC(serverSendPush);

createHashMapFromArray [["ok", true], ["roomId", _roomId], ["exists", _exists]]
#endif
