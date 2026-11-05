#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sends one push to the in-game page. The web UI hub broadcasts game messages
 * to every connected web client; SQF no longer knows or selects targets.
 *
 * Arguments:
 * 0: Command <HASHMAP>
 *
 * Return Value:
 * Delivered to the in-game page <BOOL>
 *
 * Example:
 * [createHashMapFromArray [["a", "Messaging"], ["c", "Message.New"]]] call ace_tacphone_Messaging_fnc_clientPushToWeb
 *
 * Public: No
 */

params ["_command"];

if (!("a" in _command)) then {
    _command set ["a", MESSAGING_APP];
};

[_command] call EFUNC(tacphone,sendCommandToPhone);
