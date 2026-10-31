#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Broadcasts Room.Upsert to every online participant of a room. Players that
 * were just removed receive the same room payload with "removed": true so the
 * page can drop the room.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 * 1: Removed player UIDs <ARRAY of STRING> (optional)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record] call ace_tacphone_Messaging_fnc_serverBroadcastRoom
 *
 * Public: No
 */

params ["_record", ["_removedUids", []]];

private _roomPayload = [_record] call FUNC(serverAssembleRoom);

private _push = createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "Room.Upsert"],
    ["room", _roomPayload]
];

{
    private _player = [_x] call FUNC(getPlayerByUid);

    if (!isNull _player) then {
        [_player, _push] call FUNC(serverSendPush);
    };
} forEach (keys (_record get "participants"));

if (_removedUids isEqualTo []) exitWith {};

private _removedPush = createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "Room.Upsert"],
    ["room", _roomPayload],
    ["removed", true]
];

{
    private _player = [_x] call FUNC(getPlayerByUid);

    if (!isNull _player) then {
        [_player, _removedPush] call FUNC(serverSendPush);
    };
} forEach _removedUids;
