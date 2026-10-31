#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Recomputes the effective presence of one player from all registered page
 * clients and broadcasts Presence.Changed when it changed.
 *
 * available: at least one client is visible
 * minimized: clients exist but none is visible
 * offline:   no client is registered (player disconnected or never registered)
 *
 * Arguments:
 * 0: Player UID <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["76561198000000000"] call ace_tacphone_Messaging_fnc_serverUpdatePresence
 *
 * Public: No
 */

params ["_uid"];

if (!isServer) exitWith {};
if (_uid == "") exitWith {};

private _clients = GVAR(serverPlayerClients) getOrDefault [_uid, createHashMap];
private _presence = MESSAGING_PRESENCE_OFFLINE;

if (count _clients > 0) then {
    _presence = [MESSAGING_PRESENCE_MINIMIZED, MESSAGING_PRESENCE_AVAILABLE] select (true in (values _clients));
};

if ((GVAR(serverPlayerPresence) getOrDefault [_uid, ""]) == _presence) exitWith {};

GVAR(serverPlayerPresence) set [_uid, _presence];

[_uid, _presence] call FUNC(serverBroadcastPresence);
