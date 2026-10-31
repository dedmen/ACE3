#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sends one push to the page clients of the local player: "local" plus every
 * registered WebSocket client id.
 *
 * Arguments:
 * 0: Command <HASHMAP>
 * 1: Targets <ARRAY|STRING> (optional; defaults to every page client)
 *
 * Return Value:
 * None
 *
 * Example:
 * [["Message.New"] call ace_tacphone_Messaging_fnc_newPush] call ace_tacphone_Messaging_fnc_clientPushToWeb
 *
 * Public: No
 */

params ["_command", ["_targets", []]];

if (!("a" in _command)) then {
    _command set ["a", MESSAGING_APP];
};

if (count _targets == 0) then {
    _targets = ["local"];

    {
        if (_x != "local") then {
            _targets pushBack _x;
        };
    } forEach (keys GVAR(webClients));
};

[_targets, _command] call EFUNC(tacphone,sendCommandToPhone);
