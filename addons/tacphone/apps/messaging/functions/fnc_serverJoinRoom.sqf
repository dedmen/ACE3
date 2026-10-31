#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Adds a player to a room after validating the invite key, then broadcasts the
 * updated room and syncs the full chat state back to the joining player so the
 * page gets the room history.
 *
 * Group rooms only accept players on the side of the current participants, even
 * when enemy chat is enabled. Direct rooms follow the enemy-chat setting.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "JoinRoom", "roomId": "", "inviteKey": "" })
 * 1: Sender <OBJECT> (player joining the room)
 *
 * Return Value:
 * Result <HASHMAP> ({ok, roomId})
 *
 * Example:
 * [_request, player] call ace_tacphone_Messaging_fnc_serverJoinRoom
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
private _participants = _record get "participants";

if (_uid in _participants) exitWith {
    [_sender] call FUNC(serverSync);

    createHashMapFromArray [["ok", true], ["roomId", _roomId], ["existing", true]]
};

private _inviteKey = _request getOrDefault ["inviteKey", ""];

if (_inviteKey != (_record getOrDefault ["inviteKey", ""])) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Invalid invite key"]]
};

private _allowed = true;
private _senderSide = str (side _sender);

if ((_record get "kind") == "group") then {
    {
        private _info = [_x] call FUNC(assembleParticipant);

        if ((_info getOrDefault ["side", ""]) != _senderSide) exitWith {
            _allowed = false;
        };
    } forEach (keys _participants);
} else {
    if (count _participants >= 2) then {
        // A normal direct room is already full; invites should not exist, but
        // never let a third player in.
        _allowed = false;
    } else {
        // One side left. Revive the history as a group room and validate the
        // joining player against the remaining participant's side.
        private _remainingUid = keys _participants param [0, ""];
        _allowed = _remainingUid != "" && {[_sender, _remainingUid] call FUNC(serverCanChat)};
        if (_allowed) then {
            _record set ["kind", "group"];
        };
    };
};

if (!_allowed) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Joining this room is not allowed"]]
};

if (!([_record, _uid] call FUNC(serverAddParticipantToRoom))) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Could not join the room"]]
};

// An invite sent to a group carries the group ids. The first member to join
// activates group tracking, so later in-game group changes are followed too.
private _groupIds = [];

{
    {
        if ((_x getOrDefault ["kind", ""]) != MESSAGING_INVITE_OBJECT_KIND) then { continue; };
        private _data = _x getOrDefault ["data", createHashMap];

        if ((_data getOrDefault ["inviteKey", ""]) == _inviteKey) then {
            _groupIds append (_data getOrDefault ["groupIds", []]);
        };
    } forEach (_x getOrDefault ["objects", []]);
} forEach (_record getOrDefault ["messages", []]);

{
    [_record, _x, _sender] call FUNC(serverTrackGroup);
} forEach _groupIds;

[_record] call FUNC(serverBroadcastRoom);
[_sender] call FUNC(serverSync);

createHashMapFromArray [["ok", true], ["roomId", _roomId]]
