#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Removes players from a group room. Direct rooms cannot lose participants.
 * Remaining participants receive Room.Upsert; removed players receive it with
 * "removed": true so their page can drop the room. Removing the last participant
 * deletes the room from the server maps.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "RemoveParticipants", "roomId": "", "playerUids": [] })
 * 1: Sender <OBJECT> (player sending the request)
 *
 * Return Value:
 * Result <HASHMAP> ({ok, roomId, removed})
 *
 * Example:
 * [_request, player] call ace_tacphone_Messaging_fnc_serverRemoveParticipants
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

private _participants = _record get "participants";
private _uid = getPlayerUID _sender;

if (!(_uid in _participants)) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Not a room member"]]
};

private _requestedUids = _request getOrDefault ["playerUids", []];

if ((_record get "kind") == "direct" && {!(_uid in _requestedUids)}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Direct rooms only allow leaving yourself"]]
};

// A member of a whole invited group cannot leave individually; the group stays
// in the room until the group invitation is dealt with.
private _isGroupControlled = false;

if (_uid in _requestedUids) then {
    private _selfInfo = _participants getOrDefault [_uid, createHashMap];
    private _storedGroupId = _selfInfo getOrDefault ["groupId", ""];
    private _groupControlled = _selfInfo getOrDefault ["groupControlled", false];
    private _trackedGroups = _record getOrDefault ["groups", createHashMap];
    private _liveGroupId = "";
    private _senderGroup = group _sender;

    if (!isNull _senderGroup) then {
        _liveGroupId = [_senderGroup] call FUNC(getGroupId);
    };

    // Check every representation. Older room records may have a stored id that
    // differs from the live group id, and leader/group changes must not bypass
    // the whole-group lock.
    _isGroupControlled =
        _groupControlled ||
        {_storedGroupId != "" && {_storedGroupId in _trackedGroups}} ||
        {_liveGroupId != "" && {_liveGroupId in _trackedGroups}};
};

// Top-level exitWith: an exitWith nested inside the `if` above only leaves that
// inner scope and would still execute the removal loop.
if (_isGroupControlled) exitWith {
    createHashMapFromArray [
        ["ok", false],
        ["error", "You cannot leave while your whole group is invited. Leave the in-game group or ask the room creator to remove the group invite."]
    ]
};

private _removed = [];

{
    private _targetUid = _x;

    if (_targetUid in _participants) then {
        _participants deleteAt _targetUid;

        private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefault [_targetUid, createHashMap];
        _playerRooms deleteAt _roomId;

        _removed pushBack _targetUid;
    };
} forEach (_request getOrDefault ["playerUids", []]);

if (_removed isEqualTo []) exitWith {
    createHashMapFromArray [["ok", true], ["roomId", _roomId], ["removed", 0]]
};

if ((keys _participants) isEqualTo []) then {
    [_record, _removed] call FUNC(serverDeleteRoom);
} else {
    [_record, _removed] call FUNC(serverBroadcastRoom);
};

createHashMapFromArray [["ok", true], ["roomId", _roomId], ["removed", count _removed]]
