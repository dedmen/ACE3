#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Assembles the public room list for one player: every group room with an
 * empty invite key that the player could join.
 *
 * The listing applies the exact group join rule — every participant must be
 * on the requesting player's side — so the list never contains a room the
 * player cannot join, and enemy sides never learn that a room exists. A
 * public room whose participants are on mixed sides is listed for no side.
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * Rooms <ARRAY of HASHMAP> ({id, name, kind, participants, createdAt, createdBy, lastActivity})
 *
 * Example:
 * [player] call ace_tacphone_Messaging_fnc_serverListPublicRooms
 *
 * Public: No
 */

params ["_player"];

private _side = str (side _player);
private _rooms = [];

{
    private _record = _y;

    if ((_record get "kind") != "group" || {(_record getOrDefault ["inviteKey", ""]) != ""}) then {
        continue;
    };

    private _joinable = true;

    {
        private _info = [_x] call FUNC(assembleParticipant);

        if ((_info getOrDefault ["side", ""]) != _side) exitWith {
            _joinable = false;
        };
    } forEach (keys (_record get "participants"));

    if (!_joinable) then {
        continue;
    };

    // Timestamp of the last message, or createdAt when the room has none.
    private _lastActivity = 0;
    private _messages = _record getOrDefault ["messages", []];

    if (count _messages > 0) then {
        _lastActivity = (_messages select -1) getOrDefault ["timestamp", 0];
    };

    if (_lastActivity == 0) then {
        _lastActivity = _record getOrDefault ["createdAt", 0];
    };

    _rooms pushBack createHashMapFromArray [
        ["id", _record get "id"],
        ["name", _record getOrDefault ["name", ""]],
        ["kind", "group"],
        ["participants", [_record] call FUNC(serverRoomParticipants)],
        ["createdAt", _record getOrDefault ["createdAt", 0]],
        ["createdBy", _record getOrDefault ["createdBy", ""]],
        ["lastActivity", _lastActivity]
    ];
} forEach GVAR(serverRooms);

_rooms
