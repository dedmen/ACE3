#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Adds one player to a room record and links the shared record into that
 * player's room map. Returns false when the player is unknown or already a
 * participant; side rules are validated by the caller.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 * 1: Player UID <STRING>
 *
 * Return Value:
 * Added <BOOL>
 *
 * Example:
 * [_record, "76561198000000000"] call ace_tacphone_Messaging_fnc_serverAddParticipantToRoom
 *
 * Public: No
 */

params ["_record", "_uid"];

private _participants = _record get "participants";

if (_uid in _participants) exitWith { false };

private _info = [_uid] call FUNC(assembleParticipant);

if ((_info getOrDefault ["name", ""]) == "") exitWith { false };

_info set ["creator", false];
_participants set [_uid, _info];

private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefaultCall [_uid, {createHashMap}, true];
_playerRooms set [_record get "id", _record];

true
