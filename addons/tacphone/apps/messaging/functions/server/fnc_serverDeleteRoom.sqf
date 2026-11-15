#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Deletes one room from the server maps and tells every participant (including
 * already removed ones) that it is gone. The room is also dropped from every
 * remaining participant's player map, so the function is self-contained.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 * 1: Removed PlayerUIDs <ARRAY of STRING> (optional)
 * 2: Sides of the removed UIDs <ARRAY of STRING> (optional; callers capture
 *    them with FUNC(participantSide) before removing the participant records)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record, [_uid], ["WEST"]] call ace_tacphone_Messaging_fnc_serverDeleteRoom
 *
 * Public: No
 */

params ["_record", ["_removedUids", []], ["_removedSides", []]];

private _roomId = _record get "id";

// A deleted public room must vanish from the public lists. Capture the
// affected sides before the record leaves the server maps: the current
// participants' sides plus the sides of the removed UIDs (passed in, because
// the callers delete the participant records before calling this function).
private _publicSides = [];

if ((_record get "kind") == "group" && {(_record getOrDefault ["inviteKey", ""]) == ""}) then {
    _publicSides = [_record] call FUNC(serverParticipantSides);

    {
        if (_x != "" && {!(_x in _publicSides)}) then {
            _publicSides pushBack _x;
        };
    } forEach _removedSides;
};

[_record, _removedUids] call FUNC(serverBroadcastRoom);

// Current callers already drop the room from the players' maps before
// calling, so their pre-cleanup is redundant-but-harmless.
{
    private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefault [_x, createHashMap];
    _playerRooms deleteAt _roomId;
} forEach (keys (_record get "participants"));

GVAR(serverRooms) deleteAt _roomId;

{
    [_record, _x] call FUNC(serverUntrackGroup);
} forEach (keys (_record getOrDefault ["groups", createHashMap]));

// Refreshed after the room left the maps so the pushed lists no longer
// contain it.
if (_publicSides isNotEqualTo []) then {
    [_publicSides] call FUNC(serverPushPublicRooms);
};
