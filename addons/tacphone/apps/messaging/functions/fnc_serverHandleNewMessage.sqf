#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Validates and appends a new message to a room, assigns the server message id
 * and timestamp, and pushes Message.New to the participants. The push contains
 * the clientMessageId of the request so the page can reconcile its optimistic
 * message.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "SendMessage", "roomId": "", "clientMessageId": "", "content": "", "objects": [] })
 * 1: Sender <OBJECT> (player sending the message)
 *
 * Return Value:
 * Result <HASHMAP> ({ok, roomId, messageId})
 *
 * Example:
 * [_request, player] call ace_tacphone_Messaging_fnc_serverHandleNewMessage
 *
 * Public: No
 */

params ["_request", "_sender"];

if (isNull _sender) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _roomId = _request getOrDefault ["roomId", ""];
private _record = GVAR(serverRooms) getOrDefault [_roomId, createHashMap];

if (count _record == 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Room not found"]]
};

private _uid = getPlayerUID _sender;

if (!(_uid in (_record get "participants"))) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Not a room member"]]
};

private _content = _request getOrDefault ["content", ""];
private _objects = _request getOrDefault ["objects", []];

if (_content == "" && {count _objects == 0}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Empty message"]]
};

private _messageData = createHashMapFromArray [
    ["id", ["msg:"] call FUNC(generateId)],
    ["roomId", _roomId],
    ["content", _content],
    ["objects", _objects]
];

private _clientMessageId = _request getOrDefault ["clientMessageId", ""];
if (_clientMessageId != "") then {
    _messageData set ["clientMessageId", _clientMessageId];
};

private _message = [_messageData, _sender] call FUNC(assembleMessage);

(_record get "messages") pushBack _message;
[_message, _record] call FUNC(serverPushMessage);

createHashMapFromArray [
    ["ok", true],
    ["roomId", _roomId],
    ["messageId", _message get "id"]
]
