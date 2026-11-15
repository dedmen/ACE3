#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Delivers one push to the target players (every connected player by
 * default) through the QGVAR(serverPush) target event. Each target's machine
 * receives the event on its own client handler (fnc_clientHandlePush), which
 * forwards the push to the local in-game page; the web UI hub then fans the
 * game message out to the external web clients. This is the only delivery
 * path: sendCommandToPhone only reaches the browser on the calling machine,
 * which on a dedicated server is none. The JSON is serialized once and
 * shared by every target. Request-scoped pushes (the Error push) pass
 * [sender] so only the requesting player's pages get them.
 *
 * Arguments:
 * 0: Push <HASHMAP> ({ "a": "ACE_TacPhone_Logistics", "c": "Logistics.State", ... })
 * 1: Target players <ARRAY of OBJECT> (optional; defaults to allPlayers)
 *
 * Return Value:
 * None
 *
 * Example:
 * [createHashMapFromArray [["a", "ACE_TacPhone_Logistics"], ["c", "Logistics.State"]]] call ace_tacphone_Logistics_fnc_serverPushAll
 *
 * Public: No
 */

params ["_push", ["_targets", allPlayers]];

if (!("a" in _push)) then {
    _push set ["a", LOGISTICS_APP];
};

private _pushJson = toJSON _push;

[QGVAR(serverPush), [_pushJson], _targets] call CBA_fnc_targetEvent;
