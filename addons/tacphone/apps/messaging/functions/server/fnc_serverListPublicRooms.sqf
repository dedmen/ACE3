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
 * Within one open cache scope the world is frozen, so the joinable set per
 * side is stable: the filter result is cached per side (O2) and only the
 * entries are rebuilt on every call. Outside a scope the full scan runs as
 * before.
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

// The group keeps the underlying side; a dead player would report CIVILIAN.
private _side = str (side (group _player));

private _joinableRooms = nil;

if (GVAR(serverParticipantScope) > 0) then {
    _joinableRooms = GVAR(serverPublicListCache) getOrDefault [_side, nil];
};

if (isNil "_joinableRooms") then {
    _joinableRooms = [];

    {
        // serverRooms is a hashmap: the record is the value (_y), the room
        // id is the key (_x).
        private _record = _y;

        if ((_record get "kind") != "group" || {(_record getOrDefault ["inviteKey", ""]) != ""}) then {
            continue;
        };

        private _joinable = true;
        private _participants = _record get "participants";

        {
            private _stored = _participants getOrDefault [_x, createHashMap];
            // The cached variant of FUNC(participantSide): within a scope a
            // cached side is as fresh as a live read, and without a scope it
            // falls back to the live assembly.
            private _info = [_x] call FUNC(serverCachedParticipant);
            private _participantSide = if ((_info getOrDefault ["name", ""]) != "") then {
                _info getOrDefault ["side", ""]
            } else {
                _stored getOrDefault ["side", ""]
            };

            if (_participantSide != _side) exitWith {
                _joinable = false;
            };
        } forEach (keys _participants);

        if (_joinable) then {
            _joinableRooms pushBack _record;
        };
    } forEach GVAR(serverRooms);

    if (GVAR(serverParticipantScope) > 0) then {
        GVAR(serverPublicListCache) set [_side, _joinableRooms];
    };
};

private _rooms = [];

{
    private _record = _x;

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
} forEach _joinableRooms;

_rooms
