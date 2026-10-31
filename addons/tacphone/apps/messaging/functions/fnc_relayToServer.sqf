#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Relays one page request to the mission server. On the server (single player
 * or hosted) the request is handled directly, everywhere else it is sent with
 * the QGVAR(clientRequest) server event.
 *
 * Arguments:
 * 0: Player UID <STRING>
 * 1: Page client id <STRING>
 * 2: Request <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [getPlayerUID player, "local", createHashMapFromArray [["c", "GetPlayerList"]]] call ace_tacphone_Messaging_fnc_relayToServer
 *
 * Public: No
 */

params ["_uid", "_clientId", "_request"];

if (isServer) exitWith {
    [_request, _clientId, [_uid] call FUNC(getPlayerByUid)] call FUNC(serverHandleRequest);
};

[QGVAR(clientRequest), [_uid, _clientId, toJSON _request]] call CBA_fnc_serverEvent;
