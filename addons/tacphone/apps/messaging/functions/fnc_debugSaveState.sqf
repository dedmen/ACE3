#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Exercises the disabled persistence scaffolding by saving the current server
 * state. Only compiled into builds made with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Request <HASHMAP>
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMap, player] call ace_tacphone_Messaging_fnc_debugSaveState
 *
 * Public: No
 */

params ["_request", "_sender"];

if (!isServer) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Not the server"]]
};

private _saved = [] call FUNC(serverSaveState);

createHashMapFromArray [["ok", _saved], ["saved", _saved]]
#endif
