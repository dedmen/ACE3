#include "..\..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Debug-only server-side role setter. Sets the role of the sender, or of the
 * named uid when the server cannot resolve one (Messaging fake players in the
 * live test suite).
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "Debug.SetRole", "role": "player"|"worker", "uid": "" (optional), "name": "" (optional) })
 * 1: Sender <OBJECT> (player setting the role; may be null with a uid override)
 *
 * Return Value:
 * Result <HASHMAP> (the serverSetRole result: {ok: true, pending: true} on success, {ok: true} for an unknown role)
 *
 * Example:
 * [createHashMapFromArray [["c", "Debug.SetRole"], ["role", "worker"], ["uid", "76561198000000000"], ["name", "Fake Worker"]], player] call ace_tacphone_Logistics_fnc_debugSetRole
 *
 * Public: No
 */

params ["_request", "_sender"];

if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
    createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]]
};

// Empty overrides keep the normal path: the sender's own uid and name. The
// payload values are JSON strings; `str` would add quotes to them.
private _uidOverride = _request getOrDefault ["uid", ""];
if !(_uidOverride isEqualType "") then {
    _uidOverride = "";
};

private _nameOverride = _request getOrDefault ["name", ""];
if !(_nameOverride isEqualType "") then {
    _nameOverride = "";
};

[_request, _sender, _uidOverride, _nameOverride] call FUNC(serverSetRole)
#endif
