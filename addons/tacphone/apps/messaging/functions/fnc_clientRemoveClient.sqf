#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Drops a WebSocket page client that disconnected, both locally and on the
 * server. The in-game "local" client never disconnects.
 *
 * When this runs on the server, the owning player is found by scanning the
 * registered clients; when it runs on a client the player id is known locally
 * and the removal is relayed.
 *
 * Arguments:
 * 0: Client id <STRING> (WebSocket connection id)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["3f1c2b7e-9d4a-4f7c-9d1e-5a6b7c8d9e0f"] call ace_tacphone_Messaging_fnc_clientRemoveClient
 *
 * Public: No
 */

params ["_clientId"];

if (_clientId == "" || {_clientId == "local"}) exitWith {};

GVAR(webClients) deleteAt _clientId;

if (!isServer) exitWith {
    if (!hasInterface) exitWith {};

    private _localUid = getPlayerUID player;
    if (_localUid == "") exitWith {};

    [_localUid, _clientId, createHashMapFromArray [
        ["c", "ClientDisconnect"]
    ]] call FUNC(relayToServer);
};

// Server: find the player that owned this client.
private _ownerUid = "";

{
    if (_clientId in (GVAR(serverPlayerClients) get _x)) exitWith {
        _ownerUid = _x;
    };
} forEach (keys GVAR(serverPlayerClients));

if (_ownerUid == "") exitWith {};

private _clients = GVAR(serverPlayerClients) get _ownerUid;
_clients deleteAt _clientId;

[_ownerUid] call FUNC(serverUpdatePresence);
