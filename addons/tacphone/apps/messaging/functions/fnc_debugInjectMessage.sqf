#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Appends a message to a room as a fake sender and pushes it to the connected
 * clients. Only compiled into builds made with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "roomId": "", "content": "", "senderUid": "" })
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["roomId", "grp:1_2"], ["content", "Hello"]], player] call ace_tacphone_Messaging_fnc_debugInjectMessage
 *
 * Public: No
 */

params ["_request", "_sender"];

private _roomId = _request getOrDefault ["roomId", ""];
private _record = GVAR(serverRooms) getOrDefault [_roomId, createHashMap];

if (count _record == 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Room not found"]]
};

private _senderUid = _request getOrDefault ["senderUid", ""];

if (_senderUid == "") then {
    {
        if ((_x select [0, 5]) == "fake_") exitWith {
            _senderUid = _x;
        };
    } forEach (keys (_record get "participants"));
};

if (_senderUid == "" && {!isNull _sender}) then {
    _senderUid = getPlayerUID _sender;
};

if (_senderUid == "") exitWith {
    createHashMapFromArray [["ok", false], ["error", "No sender available"]]
};

private _message = [createHashMapFromArray [
    ["id", ["msg:"] call FUNC(generateId)],
    ["roomId", _roomId],
    ["senderUid", _senderUid],
    ["content", _request getOrDefault ["content", "Debug message"]],
    ["objects", []]
], objNull] call FUNC(assembleMessage);

(_record get "messages") pushBack _message;
[_message, _record] call FUNC(serverPushMessage);

createHashMapFromArray [["ok", true], ["messageId", _message get "id"]]
#endif
