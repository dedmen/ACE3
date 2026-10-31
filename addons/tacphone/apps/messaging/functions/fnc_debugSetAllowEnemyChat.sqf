#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Overrides the enemy-chat setting on the server for tests. Only compiled into
 * builds made with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "enabled": true })
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["enabled", true]], player] call ace_tacphone_Messaging_fnc_debugSetAllowEnemyChat
 *
 * Public: No
 */

params ["_request", "_sender"];

GVAR(debugAllowEnemyChat) = _request getOrDefault ["enabled", false];

[_sender] call FUNC(serverPushPlayerList);

createHashMapFromArray [
    ["ok", true],
    ["allowEnemyChat", GVAR(debugAllowEnemyChat)]
]
#endif
