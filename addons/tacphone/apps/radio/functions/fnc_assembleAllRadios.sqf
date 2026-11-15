#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the full radio snapshot { ready, radios, tx, revision, pushMs }.
 * TFAR is a hard dependency (requiredAddons), so no capability detection.
 *
 * Arguments:
 * 0: Requested push floor in ms <NUMBER> (default: 250, clamped to 100..2000)
 *
 * Return Value:
 * Snapshot <HASHMAP>
 *
 * Example:
 * [250] call ace_tacphone_radio_fnc_assembleAllRadios
 *
 * Public: No
 */

params [["_pushMs", 250]];

_pushMs = _pushMs max 100 min MAX_PUSH_MS;

private _radios = [];

if (!isNull player) then {

    // SR handles first, then LR handles; malformed or gone LR entries are
    // dropped from the list, not reported (a bare object here would misroute
    // into the LR settings path and break TFAR's setVariable)
    private _handles = [];
    _handles append (call FUNC(srRadioClasses));
    {
        if ((_x isEqualType []) && {count _x >= 2} && {!isNull (_x select 0)}
            && {(_x select 1) isEqualType ""}) then {
            _handles pushBack _x;
        };
    } forEach (player call TFAR_fnc_LRRadiosList);

    {
        _radios pushBack (_x call FUNC(assembleRadioState));
    } forEach _handles;
};

// The live transmission, null when idle
private _tx = nil;
private _txState = GVAR(tx);
if (!isNil "_txState") then {
    _tx = createHashMapFromArray [
        ["radioId", _txState get "radio"],
        ["channel", _txState get "channel"],
        ["additional", _txState get "additional"],
        ["source", _txState get "source"]
    ];
};

createHashMapFromArray [
    ["ready", _radios isNotEqualTo []],
    ["radios", _radios],
    ["tx", _tx],
    ["revision", GVAR(revision)],
    ["pushMs", _pushMs]
]
