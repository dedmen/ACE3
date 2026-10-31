#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Adds players and current members of selected groups to an existing group room.
 * Groups are resolved on the server to their current human members and are
 * always limited to the requesting player's side. Player targets follow the
 * enemy-chat setting.
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

// A direct room normally has two people. Once one side leaves, the remaining
// player may revive the history by adding someone; it then becomes a group.
if ((_record get "kind") == "direct" && {count _participants >= 2}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Direct rooms cannot get new participants while both sides remain"]]
};

private _added = 0;

{
    private _targetUid = _x;

    if (!(_targetUid in _participants) && {[_sender, _targetUid] call FUNC(serverCanChat)}) then {
        if ([_record, _targetUid] call FUNC(serverAddParticipantToRoom)) then {
            _added = _added + 1;
        };
    };
} forEach (_request getOrDefault ["playerUids", []]);

{
    _added = _added + ([_record, _x, _sender] call FUNC(serverTrackGroup));
} forEach (_request getOrDefault ["groupIds", []]);

if (_added > 0) then {
    if ((_record get "kind") == "direct") then {
        _record set ["kind", "group"];
    };

    [_record] call FUNC(serverBroadcastRoom);
};

createHashMapFromArray [["ok", true], ["roomId", _roomId], ["added", _added]]
