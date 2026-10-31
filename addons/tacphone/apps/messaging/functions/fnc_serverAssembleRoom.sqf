#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Converts an internal room record into the wire representation sent to the
 * web UI, including current participant presence.
 *
 * Participants that are no longer known (disconnected and no longer in the
 * game) fall back to the record stored at room creation time, refreshed with
 * their current presence.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 *
 * Return Value:
 * Room <HASHMAP> (without messages)
 *
 * Example:
 * [GVAR(serverRooms) get "grp:1_2"] call ace_tacphone_Messaging_fnc_serverAssembleRoom
 *
 * Public: No
 */

params ["_roomRecord"];

private _storedParticipants = _roomRecord get "participants";
private _participants = [];

{
    private _uid = _x;
    private _stored = _storedParticipants getOrDefault [_uid, createHashMap];
    private _info = [_uid] call FUNC(assembleParticipant);

    if ((_info getOrDefault ["name", ""]) == "" && {count _stored > 0}) then {
        _info = _stored;
        _info set ["presence", [_uid] call FUNC(getPresence)];
    };

    if (_stored getOrDefault ["creator", false]) then {
        _info set ["creator", true];
    };

    // The whole-group flag lives on the room's group record, not on a leader;
    // expose the effective flag on every current member of that group.
    private _trackedGroups = _roomRecord getOrDefault ["groups", createHashMap];

    if ((_info getOrDefault ["groupId", ""]) in _trackedGroups) then {
        _info set ["groupInvited", true];
    };

    _participants pushBack _info;
} forEach (keys _storedParticipants);

createHashMapFromArray [
    ["id", _roomRecord get "id"],
    ["kind", _roomRecord get "kind"],
    ["name", _roomRecord getOrDefault ["name", ""]],
    ["participants", _participants],
    ["createdAt", _roomRecord getOrDefault ["createdAt", 0]],
    ["createdBy", _roomRecord getOrDefault ["createdBy", ""]]
]
