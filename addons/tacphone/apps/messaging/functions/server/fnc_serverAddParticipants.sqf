#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Adds players and current members of selected groups to an existing room.
 * Groups are resolved on the server to their current human members and are
 * always limited to the requesting player's side. Player targets follow the
 * enemy-chat setting.
 *
 * A direct room that receives new participants is flipped to a group room
 * before the targets are added: group tracking only accepts group rooms, and
 * the flip must be in place when the targets resolve. Every newly added
 * player receives the room's full history, the same way a joiner does.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "AddParticipants", "roomId": "", "playerUids": [], "groupIds": [] })
 * 1: Sender <OBJECT> (player sending the request)
 *
 * Return Value:
 * Result <HASHMAP> ({ok, roomId, added})
 *
 * Example:
 * [_request, player] call ace_tacphone_Messaging_fnc_serverAddParticipants
 *
 * Public: No
 */

params ["_request", "_sender"];

REQUIRE_SENDER(_sender);

private _roomId = _request getOrDefault ["roomId", ""];
private _record = createHashMap;
ROOM_OR_ERROR(_record,_roomId,"Room not found");

private _participants = _record get "participants";
private _uid = getPlayerUID _sender;

if (!(_uid in _participants)) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Not a room member"]]
};

// A direct room normally has two people. Once one side leaves, the remaining
// player may revive the history by adding someone; it then becomes a group.
if ((_record get "kind") == "direct" && {count _participants >= 2}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Direct rooms cannot get new participants while both sides remain"]]
};

// Sides of the current participants before the mutation; a public room's
// lists must be refreshed for every side involved in the change.
private _oldSides = [_record] call FUNC(serverParticipantSides);

// Reviving a direct room turns it into a group room. The flip must happen
// before the targets resolve: group tracking only accepts group rooms, so a
// direct room would otherwise silently drop every group target. Guarded on
// having targets so an empty request does not flip the kind without a
// broadcast to announce it.
private _hasTargets = count (_request getOrDefault ["playerUids", []]) > 0
    || count (_request getOrDefault ["groupIds", []]) > 0;

if ((_record get "kind") == "direct" && {_hasTargets}) then {
    _record set ["kind", "group"];
};

private _added = 0;
private _addedUids = [];

{
    private _targetUid = _x;

    if (!(_targetUid in _participants) && {[_sender, _targetUid] call FUNC(serverCanChat)}) then {
        if ([_record, _targetUid] call FUNC(serverStoreRoom)) then {
            _added = _added + 1;
            _addedUids pushBack _targetUid;
        };
    };
} forEach (_request getOrDefault ["playerUids", []]);

{
    // Group members are added inside serverTrackGroup; diffing the
    // participant map before and after names the new ones.
    private _before = keys _participants;

    _added = _added + ([_record, _x, _sender] call FUNC(serverTrackGroup));
    {
        if (!(_x in _before)) then {
            _addedUids pushBack _x;
        };
    } forEach (keys _participants);
} forEach (_request getOrDefault ["groupIds", []]);

if (_added > 0) then {
    [_record] call FUNC(serverBroadcastRoom);

    // The broadcast carries the room, not its history; a newly added player
    // receives the full room state the same way a joiner does.
    {
        private _player = [_x] call FUNC(getPlayerByUid);
        if (!isNull _player) then {
            [_player, _record] call FUNC(serverBroadcastRoom);
        };
    } forEach _addedUids;

    if ((_record get "kind") == "group" && {(_record getOrDefault ["inviteKey", ""]) == ""}) then {
        private _sides = +_oldSides;
        { _sides pushBackUnique _x; } forEach ([_record] call FUNC(serverParticipantSides));
        [_sides] call FUNC(serverPushPublicRooms);
    };
};

createHashMapFromArray [["ok", true], ["roomId", _roomId], ["added", _added]]
