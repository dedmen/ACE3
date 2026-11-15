#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Creates, stores and updates a room record.
 *
 * Called with a room id (plus kind, name, participant UIDs and creator UID) it
 * builds the record, stores it in the global room map and in every
 * participant's map, and returns it. The participants map stores one entry per
 * participant (info plus creator flag). The exact same record hashmap (and
 * therefore the same messages array) is stored everywhere, so a new message is
 * visible to every participant without copying.
 *
 * Called with an existing room record (plus a PlayerUID) it adds the player as
 * participant and links the shared record into that player's room map. It
 * returns false when the player is unknown or already a participant; side
 * rules are validated by the caller.
 *
 * Arguments:
 * 0: Room id <STRING> or existing room record <HASHMAP>
 * 1: Room kind <STRING> (new room) / Player UID <STRING> (existing record)
 * 2: Room name <STRING> (new room only)
 * 3: Participant UIDs <ARRAY of STRING> (new room only)
 * 4: Creator UID <STRING> (new room only)
 *
 * Return Value:
 * Room record <HASHMAP> (new room) or added <BOOL> (existing record)
 *
 * Example:
 * ["grp:1_2", "group", "Squad", ["76561198000000000"], "76561198000000000"] call ace_tacphone_Messaging_fnc_serverStoreRoom
 * [_record, "76561198000000000"] call ace_tacphone_Messaging_fnc_serverStoreRoom
 *
 * Public: No
 */

params ["_recordOrRoomId", "_second", ["_name", ""], ["_uids", []], ["_createdBy", ""]];

if (_recordOrRoomId isEqualType "") exitWith {
    private _participants = createHashMap;

    {
        private _info = [_x] call FUNC(assembleParticipant);
        _info set ["creator", _x == _createdBy];
        _participants set [_x, _info];
    } forEach _uids;

    private _record = createHashMapFromArray [
        ["id", _recordOrRoomId],
        ["kind", _second],
        ["name", _name],
        ["participants", _participants],
        ["groups", createHashMap],
        ["messages", []],
        ["createdAt", time],
        ["createdBy", _createdBy],
        ["inviteKey", format ["%1-%2", round (random 999999), round (random 999999)]]
    ];

    GVAR(serverRooms) set [_recordOrRoomId, _record];

    {
        private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefaultCall [_x, {createHashMap}, true];
        _playerRooms set [_recordOrRoomId, _record];
    } forEach (keys _participants);

    _record
};

// Existing record: _second is the PlayerUID to add.
private _participants = _recordOrRoomId get "participants";

if (_second in _participants) exitWith { false };

private _info = [_second] call FUNC(assembleParticipant);

if ((_info getOrDefault ["name", ""]) == "") exitWith { false };

// Re-adding a room's creator (reviving a direct room) keeps their badge.
_info set ["creator", _second == (_recordOrRoomId getOrDefault ["createdBy", ""])];
_participants set [_second, _info];

private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefaultCall [_second, {createHashMap}, true];
_playerRooms set [_recordOrRoomId get "id", _recordOrRoomId];

true
