#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Client-side handler for a server push. Every push is forwarded to this
 * player's page clients unchanged; the web store is the only place that keeps
 * chat state.
 *
 * Arguments:
 * 0: Push <HASHMAP> ({ "a": "Messaging", "c": "Message.New", ... })
 *
 * Return Value:
 * None
 *
 * Example:
 * [createHashMapFromArray [["c", "Presence.Changed"]]] call ace_tacphone_Messaging_fnc_clientHandlePush
 *
 * Public: No
 */

params ["_push"];

if (!(_push isEqualType createHashMap)) exitWith {};

private _clientId = _push getOrDefault ["_client", ""];
_push deleteAt "_client";

if (_clientId != "") then {
    [_push, [_clientId]] call FUNC(clientPushToWeb);
} else {
    [_push] call FUNC(clientPushToWeb);
};
