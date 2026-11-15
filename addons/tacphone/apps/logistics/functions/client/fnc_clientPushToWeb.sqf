#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Sends one push to the local in-game page. The web UI hub broadcasts game
 * messages to every connected web client; SQF no longer knows or selects
 * targets.
 *
 * Arguments:
 * 0: Command <HASHMAP>
 *
 * Return Value:
 * Delivered to the in-game page <BOOL>
 *
 * Example:
 * [createHashMapFromArray [["a", "ACE_TacPhone_Logistics"], ["c", "Logistics.State"]]] call ace_tacphone_Logistics_fnc_clientPushToWeb
 *
 * Public: No
 */

params ["_command"];

if (!("a" in _command)) then {
    _command set ["a", LOGISTICS_APP];
};

// Logistics pushes are broadcasts by design; a player without an open phone
// is expected, not an error, so the drop stays out of the RPT.
[_command, true] call EFUNC(tacphone,sendCommandToPhone);
