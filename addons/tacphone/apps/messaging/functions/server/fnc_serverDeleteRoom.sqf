#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Deletes one room from the server maps and tells every participant (including
 * already removed ones) that it is gone.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 * 1: Removed PlayerUIDs <ARRAY of STRING> (optional)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record, [_uid]] call ace_tacphone_Messaging_fnc_serverDeleteRoom
 *
 * Public: No
 */

params ["_record", ["_removedUids", []]];

private _roomId = _record get "id";

// A deleted public room must vanish from the public lists. Capture the
// affected sides before the record leaves the server maps: the current
// participants' sides plus the sides of the removed UIDs.
private _publicSides = [];

if ((_record get "kind") == "group" && {(_record getOrDefault ["inviteKey", ""]) == ""}) then {
    _publicSides = [_record] call FUNC(serverParticipantSides);

    {
        private _side = [_x] call FUNC(assembleParticipant) getOrDefault ["side", ""];

        if (_side != "" && {!(_side in _publicSides)}) then {
            _publicSides pushBack _side;
        };
    } forEach _removedUids;
};

[_record, _removedUids] call FUNC(serverBroadcastRoom);

GVAR(serverRooms) deleteAt _roomId;

{
    [_record, _x] call FUNC(serverUntrackGroup);
} forEach (keys (_record getOrDefault ["groups", createHashMap]));

// Refreshed after the room left the maps so the pushed lists no longer
// contain it.
if (_publicSides isNotEqualTo []) then {
    [_publicSides] call FUNC(serverPushPublicRooms);
};
