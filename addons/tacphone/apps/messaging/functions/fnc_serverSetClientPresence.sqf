#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Registers or updates one page client of a player on the server and recomputes
 * the player's effective presence.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Page client id <STRING>
 * 2: Client visible <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "local", true] call ace_tacphone_Messaging_fnc_serverSetClientPresence
 *
 * Public: No
 */

params ["_sender", "_clientId", "_visible"];

if (!isServer) exitWith {};
if (isNull _sender) exitWith {};

private _uid = getPlayerUID _sender;
if (_uid == "") exitWith {};

private _clients = GVAR(serverPlayerClients) getOrDefaultCall [_uid, {createHashMap}, true];
_clients set [_clientId, _visible];

[_uid] call FUNC(serverUpdatePresence);
