#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Forwards a message to an existing room or to a new room, keeping its content
 * and objects and adding the forwarded-origin header. The forwarding player
 * becomes the sender of the new message; the original sender and group are kept
 * in the forwarded header.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "ForwardMessage", "sourceRoomId": "", "messageId": "", "targetRoomId": "", "newRoom": {} })
 * 1: Sender <OBJECT> (player forwarding the message)
 *
 * Return Value:
 * Result <HASHMAP> ({ok, roomId, messageId})
 *
 * Example:
 * [_request, player] call ace_tacphone_Messaging_fnc_serverForwardMessage
 *
 * Public: No
 */

params ["_request", "_sender"];

if (isNull _sender) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _sourceRoomId = _request getOrDefault ["sourceRoomId", ""];
private _sourceRecord = GVAR(serverRooms) getOrDefault [_sourceRoomId, createHashMap];

if (count _sourceRecord == 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Source room not found"]]
};

private _uid = getPlayerUID _sender;

if (!(_uid in (_sourceRecord get "participants"))) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Not a member of the source room"]]
};

private _messageId = _request getOrDefault ["messageId", ""];
private _original = createHashMap;

{
    if ((_x getOrDefault ["id", ""]) == _messageId) exitWith {
        _original = _x;
    };
} forEach (_sourceRecord get "messages");

if (count _original == 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Message not found"]]
};

private _targetRoomId = _request getOrDefault ["targetRoomId", ""];
private _targetRecord = createHashMap;

if (_targetRoomId != "") then {
    _targetRecord = GVAR(serverRooms) getOrDefault [_targetRoomId, createHashMap];

    if (count _targetRecord == 0) exitWith {
        createHashMapFromArray [["ok", false], ["error", "Target room not found"]]
    };

    if (!(_uid in (_targetRecord get "participants"))) exitWith {
        createHashMapFromArray [["ok", false], ["error", "Not a member of the target room"]]
    };
} else {
    private _newRoom = _request getOrDefault ["newRoom", createHashMap];

    if (count _newRoom == 0) exitWith {
        createHashMapFromArray [["ok", false], ["error", "No target room"]]
    };

    private _createResult = [createHashMapFromArray [
        ["c", "CreateRoom"],
        ["room", _newRoom]
    ], _sender] call FUNC(serverCreateRoom);

    if (!(_createResult getOrDefault ["ok", false])) exitWith {
        _createResult
    };

    _targetRoomId = _createResult getOrDefault ["roomId", ""];
    _targetRecord = GVAR(serverRooms) getOrDefault [_targetRoomId, createHashMap];
};

if (count _targetRecord == 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Target room not found"]]
};

private _forwarded = createHashMapFromArray [
    ["roomId", _sourceRoomId],
    ["roomName", _sourceRecord getOrDefault ["name", ""]],
    ["senderUid", _original getOrDefault ["senderUid", ""]],
    ["senderName", _original getOrDefault ["senderName", ""]],
    ["timestamp", _original getOrDefault ["timestamp", 0]]
];

private _originalGroupName = _original getOrDefault ["senderGroupName", ""];
if (_originalGroupName != "") then {
    _forwarded set ["senderGroupName", _originalGroupName];
};

private _messageData = createHashMapFromArray [
    ["id", ["msg:"] call FUNC(generateId)],
    ["roomId", _targetRoomId],
    ["content", _original getOrDefault ["content", ""]],
    ["objects", _original getOrDefault ["objects", []]],
    ["forwarded", _forwarded]
];

private _clientMessageId = _request getOrDefault ["clientMessageId", ""];
if (_clientMessageId != "") then {
    _messageData set ["clientMessageId", _clientMessageId];
};

private _message = [_messageData, _sender] call FUNC(assembleMessage);

(_targetRecord get "messages") pushBack _message;
[_message, _targetRecord] call FUNC(serverPushMessage);

createHashMapFromArray [
    ["ok", true],
    ["roomId", _targetRoomId],
    ["messageId", _message get "id"]
]
