#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sends one room of a player's chat state, chunked to MESSAGING_SYNC_CHUNK_SIZE
 * messages per ChatState.Room push.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Room record <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, GVAR(serverRooms) get "grp:1_2"] call ace_tacphone_Messaging_fnc_serverSyncRoom
 *
 * Public: No
 */

params ["_player", "_roomRecord"];

if (isNull _player) exitWith {};

private _messages = _roomRecord get "messages";
private _total = count _messages;
private _chunks = ceil (_total / MESSAGING_SYNC_CHUNK_SIZE);

if (_chunks < 1) then {
    _chunks = 1;
};

private _roomPayload = [_roomRecord] call FUNC(serverAssembleRoom);

for "_chunk" from 0 to (_chunks - 1) do {
    private _slice = [];

    if (_total > 0) then {
        _slice = _messages select [_chunk * MESSAGING_SYNC_CHUNK_SIZE, MESSAGING_SYNC_CHUNK_SIZE];
    };

    [_player, createHashMapFromArray [
        ["a", MESSAGING_APP],
        ["c", "ChatState.Room"],
        ["room", _roomPayload],
        ["messages", _slice],
        ["chunk", _chunk],
        ["chunks", _chunks]
    ]] call FUNC(serverSendPush);
};
