#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Reads persisted state from missionProfileNamespace and validates its schema
 * version. Persistence is disabled; nothing loads automatically.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Serialized state <HASHMAP> (empty when nothing valid is stored)
 *
 * Example:
 * [] call ace_tacphone_Messaging_fnc_serverLoadState
 *
 * Public: No
 */

private _raw = missionProfileNamespace getVariable [MESSAGING_PERSISTENCE_KEY, ""];

if (_raw isEqualTo "") exitWith {
    createHashMap
};

private _state = if (_raw isEqualType "") then {
    fromJSON _raw
} else {
    _raw
};

if (!(_state isEqualType createHashMap)) exitWith {
    diag_log "[TacPhone Messaging] Stored state is not a hashmap";
    createHashMap
};

private _version = _state getOrDefault ["version", -1];

if (_version != MESSAGING_PERSISTENCE_VERSION) exitWith {
    diag_log format ["[TacPhone Messaging] Ignoring stored state with schema version %1", _version];
    createHashMap
};

_state
