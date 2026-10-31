#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sends the full chat state of one player to a client, chunked per room, and
 * finishes with ChatState.Done.
 *
 * Arguments:
 * 0: Player <OBJECT> whose rooms should be synced
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call ace_tacphone_Messaging_fnc_serverSync
 *
 * Public: No
 */

params ["_player"];

// Singleplayer can hand us objNull when the request came through a relay; the
// mission server player is the only participant there.
if (isNull _player && {isServer} && {!isDedicated}) then {
    _player = player;
};

if (isNull _player) exitWith {};

private _rooms = GVAR(serverRoomsByPlayer) getOrDefault [getPlayerUID _player, createHashMap];

{
    [_player, _x] call FUNC(serverSyncRoom);
} forEach (values _rooms);

[_player, createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "ChatState.Done"],
    ["rooms", count _rooms]
]] call FUNC(serverSendPush);
