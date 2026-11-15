#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Client-side handler for a server push (QGVAR(serverPush) target event).
 * Forwards the push to this player's in-game page unchanged; the web store is
 * the only place that keeps logistics state, exactly like the Messaging push
 * path.
 *
 * Arguments:
 * 0: Push <HASHMAP> ({ "a": "ACE_TacPhone_Logistics", "c": "Logistics.State", ... })
 *
 * Return Value:
 * None
 *
 * Example:
 * [createHashMapFromArray [["c", "Logistics.State"]]] call ace_tacphone_Logistics_fnc_clientHandlePush
 *
 * Public: No
 */

params ["_push"];

// The push is already verified as a hashmap by the serverPush handler in XEH_postInit.sqf.
[_push] call FUNC(clientPushToWeb);
