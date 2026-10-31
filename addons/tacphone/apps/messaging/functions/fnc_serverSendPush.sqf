#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sends one push to a single player through the QGVAR(serverPush) target event.
 * Adds the `now` server time when the push does not have one.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Push <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, ["Message.New"] call ace_tacphone_Messaging_fnc_newPush] call ace_tacphone_Messaging_fnc_serverSendPush
 *
 * Public: No
 */

params ["_player", "_push", ["_clientId", ""]];

if (isNull _player) exitWith {};

if (!("a" in _push)) then {
    _push set ["a", MESSAGING_APP];
};

if (!("now" in _push)) then {
    _push set ["now", time];
};

// Error/result pushes can be scoped to the page client that made the request;
// the client-side handler strips this internal field before forwarding.
if (_clientId != "") then {
    _push set ["_client", _clientId];
};

[QGVAR(serverPush), [toJSON _push], _player] call CBA_fnc_targetEvent;
