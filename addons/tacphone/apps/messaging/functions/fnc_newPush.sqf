#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Creates the base of a game -> web push. Every push carries the app routing key
 * and the command; FUNC(serverSendPush) adds the `now` server time.
 *
 * Arguments:
 * 0: Push command <STRING>
 *
 * Return Value:
 * Push <HASHMAP>
 *
 * Example:
 * ["Message.New"] call ace_tacphone_Messaging_fnc_newPush
 *
 * Public: No
 */

params ["_command"];

createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", _command]
]
