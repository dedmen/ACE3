#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Creates a direct or group room, stores it in the server maps and pushes the
 * new room to every online participant.
 *
 * Direct rooms always contain exactly the creator and one other player and use
 * the deterministic id "dm:<lower uid>:<higher uid>". Creating an existing
 * direct room again only re-broadcasts it. Group rooms get a
 * "grp:<counter>_<random>" id. Player targets follow the enemy-chat setting;
 * group targets always have to be on the creator's side.
 *
 * A group room spec may carry "public": true, which clears the invite key
 * after storage so any same-side player can join the room without an invite.
 * Direct rooms ignore the flag.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "CreateRoom", "room": { "kind": "group", ... } })
 * 1: Sender <OBJECT> (player creating the room)
 *
 * Return Value:
 * Result <HASHMAP> ({ok, roomId})
 *
 * Example:
 * [_request, player] call ace_tacphone_Messaging_fnc_serverCreateRoom
 *
 * Public: No
 */

params ["_request", "_sender"];

REQUIRE_SENDER(_sender);

private _spec = _request getOrDefault ["room", createHashMap];

if (count _spec == 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Missing room specification"]]
};

private _kind = _spec getOrDefault ["kind", "group"];
private _uid = getPlayerUID _sender;

// Always includes the creator.
private _targets = [_uid];

{
    private _targetUid = _x;

    if (_targetUid != "" && {!(_targetUid in _targets)}) then {
        private _info = [_targetUid] call FUNC(assembleParticipant);

        if ((_info getOrDefault ["name", ""]) != "" && {[_sender, _targetUid] call FUNC(serverCanChat)}) then {
            _targets pushBack _targetUid;
        };
    };
} forEach (_spec getOrDefault ["playerUids", []]);

// Groups are tracked separately after the room exists, so membership changes
// can be followed through the engine group event handlers.
private _groupIds = _spec getOrDefault ["groupIds", []];

if (_kind == "direct") exitWith {
    if (count _targets != 2) exitWith {
        createHashMapFromArray [["ok", false], ["error", "Direct rooms need exactly one other participant"]]
    };

    private _otherUid = _targets select 1;

    if (!([_sender, _otherUid] call FUNC(serverCanChat))) exitWith {
        createHashMapFromArray [["ok", false], ["error", "Chatting with this player is not allowed"]]
    };

    private _uids = [_uid, _otherUid];
    _uids sort true;

    private _roomId = format ["dm:%1:%2", _uids select 0, _uids select 1];
    private _existing = GVAR(serverRooms) getOrDefault [_roomId, createHashMap];

    if (count _existing > 0) exitWith {
        [_existing] call FUNC(serverBroadcastRoom);

        createHashMapFromArray [["ok", true], ["roomId", _roomId], ["existing", true]]
    };

    private _record = [_roomId, "direct", "", _targets, _uid] call FUNC(serverStoreRoom);
    [_record] call FUNC(serverBroadcastRoom);

    createHashMapFromArray [["ok", true], ["roomId", _roomId]]
};

// A group room may start with only the creator; participants are added later.
private _roomName = _spec getOrDefault ["name", ""];
private _public = _spec getOrDefault ["public", false];
private _groupRoomId = ["grp:"] call FUNC(generateId);
private _groupRecord = [_groupRoomId, "group", _roomName, _targets, _uid] call FUNC(serverStoreRoom);

// A public room's empty invite key lets any same-side player join it without
// an invite; the shared record reference keeps the cleared key visible in
// every stored view.
if (_public) then {
    _groupRecord set ["inviteKey", ""];
};

{
    [_groupRecord, _x, _sender] call FUNC(serverTrackGroup);
} forEach _groupIds;

[_groupRecord] call FUNC(serverBroadcastRoom);

if (_public) then {
    [[_groupRecord] call FUNC(serverParticipantSides)] call FUNC(serverPushPublicRooms);
};

createHashMapFromArray [["ok", true], ["roomId", _groupRoomId]]
