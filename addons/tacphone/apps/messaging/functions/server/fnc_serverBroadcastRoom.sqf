#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Pushes a room's state to the players that need it.
 *
 * Called with a room record it broadcasts Room.Upsert to every online
 * participant; players passed as removed UIDs receive the same room payload
 * with "removed": true so the page can drop the room.
 *
 * Called with a player and a room record it sends that one player the full
 * room history, chunked to MESSAGING_SYNC_CHUNK_SIZE messages per
 * ChatState.Room push.
 *
 * The room payload is the wire representation including current participant
 * presence and the derived isPublic flag (group room with an empty invite
 * key). Participants that are no longer known (disconnected and no longer
 * in the game) fall back to the record stored at room creation time,
 * refreshed with their current presence.
 *
 * Arguments:
 * 0: Room record <HASHMAP> (broadcast) or player <OBJECT> (sync)
 * 1: Removed player UIDs <ARRAY of STRING> (broadcast, optional) / room record <HASHMAP> (sync)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record] call ace_tacphone_Messaging_fnc_serverBroadcastRoom
 * [_record, [_uid]] call ace_tacphone_Messaging_fnc_serverBroadcastRoom
 * [player, _record] call ace_tacphone_Messaging_fnc_serverBroadcastRoom
 *
 * Public: No
 */

params ["_recordOrPlayer", ["_second", []]];

private _isBroadcast = _recordOrPlayer isEqualType createHashMap;

if (!_isBroadcast && {isNull _recordOrPlayer}) exitWith {};

private _record = if (_isBroadcast) then { _recordOrPlayer } else { _second };

private _participants = [_record] call FUNC(serverRoomParticipants);
private _isPublic = (_record get "kind") == "group" && {(_record getOrDefault ["inviteKey", ""]) == ""};

private _roomPayload = createHashMapFromArray [
    ["id", _record get "id"],
    ["kind", _record get "kind"],
    ["name", _record getOrDefault ["name", ""]],
    ["participants", _participants],
    ["createdAt", _record getOrDefault ["createdAt", 0]],
    ["createdBy", _record getOrDefault ["createdBy", ""]],
    ["isPublic", _isPublic]
];

if (_isBroadcast) exitWith {
    private _push = createHashMapFromArray [
        ["a", MESSAGING_APP],
        ["c", "Room.Upsert"],
        ["room", _roomPayload]
    ];

    [keys (_record get "participants"), _push] call FUNC(serverPushToUids);

    if (_second isEqualTo []) exitWith {};

    private _removedPush = createHashMapFromArray [
        ["a", MESSAGING_APP],
        ["c", "Room.Upsert"],
        ["room", _roomPayload],
        ["removed", true]
    ];

    [_second, _removedPush] call FUNC(serverPushToUids);
};

private _messages = _record get "messages";
private _total = count _messages;
private _chunks = ceil (_total / MESSAGING_SYNC_CHUNK_SIZE);

if (_chunks < 1) then {
    _chunks = 1;
};

for "_chunk" from 0 to (_chunks - 1) do {
    private _slice = [];

    if (_total > 0) then {
        _slice = _messages select [_chunk * MESSAGING_SYNC_CHUNK_SIZE, MESSAGING_SYNC_CHUNK_SIZE];
    };

    [_recordOrPlayer, createHashMapFromArray [
        ["a", MESSAGING_APP],
        ["c", "ChatState.Room"],
        ["room", _roomPayload],
        ["messages", _slice],
        ["chunk", _chunk],
        ["chunks", _chunks]
    ]] call FUNC(serverSendPush);
};
