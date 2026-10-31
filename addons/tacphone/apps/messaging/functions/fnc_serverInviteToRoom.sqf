#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sends a room invite message containing the room id, room name and invite key
 * to the selected players, or creates a new room first when no room id is given.
 *
 * The invite is a normal chat message whose `objects` entry has the kind
 * MESSAGING_INVITE_OBJECT_KIND ("messaging.room_invite"). It is stored once in the
 * room and pushed to the room participants and to every invited player, even
 * though the invited players are not participants yet. When they join, the same
 * message id is part of the room sync, so the page can deduplicate it by id.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "InviteToRoom", "roomId": "", "newRoom": {}, "playerUids": [], "groupIds": [] })
 * 1: Sender <OBJECT> (player sending the invite)
 *
 * Return Value:
 * Result <HASHMAP> ({ok, roomId, invited})
 *
 * Example:
 * [_request, player] call ace_tacphone_Messaging_fnc_serverInviteToRoom
 *
 * Public: No
 */

params ["_request", "_sender"];

if (isNull _sender) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _roomId = _request getOrDefault ["roomId", ""];
private _record = createHashMap;
private _uid = getPlayerUID _sender;

if (_roomId != "") then {
    _record = GVAR(serverRooms) getOrDefault [_roomId, createHashMap];

    if (count _record == 0) exitWith {
        createHashMapFromArray [["ok", false], ["error", "Room not found"]]
    };

    if (!(_uid in (_record get "participants"))) exitWith {
        createHashMapFromArray [["ok", false], ["error", "Not a room member"]]
    };
} else {
    private _newRoom = _request getOrDefault ["newRoom", createHashMap];

    if (count _newRoom == 0) exitWith {
        createHashMapFromArray [["ok", false], ["error", "No room to invite to"]]
    };

    private _createResult = [createHashMapFromArray [
        ["c", "CreateRoom"],
        ["room", _newRoom]
    ], _sender] call FUNC(serverCreateRoom);

    if (!(_createResult getOrDefault ["ok", false])) exitWith {
        _createResult
    };

    _roomId = _createResult getOrDefault ["roomId", ""];
    _record = GVAR(serverRooms) getOrDefault [_roomId, createHashMap];
};

if (count _record == 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Room not found"]]
};

private _participants = _record get "participants";
private _senderSide = str (side _sender);

private _invitedUids = [];

{
    private _targetUid = _x;

    if (!(_targetUid in _participants) && {!(_targetUid in _invitedUids)} && {[_sender, _targetUid] call FUNC(serverCanChat)}) then {
        _invitedUids pushBack _targetUid;
    };
} forEach (_request getOrDefault ["playerUids", []]);

{
    {
        if (!(_x in _participants) && {!(_x in _invitedUids)}) then {
            private _info = [_x] call FUNC(assembleParticipant);

            if ((_info getOrDefault ["side", ""]) == _senderSide) then {
                _invitedUids pushBack _x;
            };
        };
    } forEach ([_x] call FUNC(getGroupMemberUids));
} forEach (_request getOrDefault ["groupIds", []]);

if (_invitedUids isEqualTo []) exitWith {
    createHashMapFromArray [["ok", true], ["roomId", _roomId], ["invited", 0]]
};

private _roomName = _record getOrDefault ["name", ""];
private _inviteKey = _record getOrDefault ["inviteKey", ""];

private _inviteObject = createHashMapFromArray [
    ["kind", MESSAGING_INVITE_OBJECT_KIND],
    ["version", MESSAGING_INVITE_OBJECT_VERSION],
    ["data", createHashMapFromArray [
        ["roomId", _roomId],
        ["roomName", _roomName],
        ["inviteKey", _inviteKey],
        ["groupIds", _request getOrDefault ["groupIds", []]]
    ]],
    ["preview", createHashMapFromArray [
        ["title", _roomName],
        ["subtitle", "Room invite"]
    ]]
];

private _message = [createHashMapFromArray [
    ["id", ["msg:"] call FUNC(generateId)],
    ["roomId", _roomId],
    ["content", ""],
    ["objects", [_inviteObject]]
], _sender] call FUNC(assembleMessage);

(_record get "messages") pushBack _message;

// Room participants see the invite like any other message.
[_message, _record] call FUNC(serverPushMessage);

// Invited players are not participants yet, push the invite to them directly.
private _push = createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "Message.New"],
    ["message", _message]
];

{
    private _player = [_x] call FUNC(getPlayerByUid);

    if (!isNull _player) then {
        [_player, _push] call FUNC(serverSendPush);
    };
} forEach _invitedUids;

createHashMapFromArray [
    ["ok", true],
    ["roomId", _roomId],
    ["invited", count _invitedUids]
]
