#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Clears every page client of a disconnected player and broadcasts the
 * resulting offline presence to the players they shared rooms with.
 *
 * Rooms are kept: the player may reconnect and sync them again.
 *
 * Arguments:
 * 0: Disconnected player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call ace_tacphone_Messaging_fnc_serverPlayerDisconnected
 *
 * Public: No
 */

params ["_unit"];

if (!isServer) exitWith {};
if (isNull _unit) exitWith {};

private _uid = getPlayerUID _unit;
if (_uid == "") exitWith {};

GVAR(serverPlayerClients) deleteAt _uid;

[_uid] call FUNC(serverUpdatePresence);
