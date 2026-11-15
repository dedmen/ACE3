#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sets the volume of a radio (0..10, validated by the web before sending).
 *
 * Arguments:
 * 0: Radio id <STRING>
 * 1: Volume <NUMBER> (0..10)
 *
 * Return Value:
 * Reply <HASHMAP> ({ ok, radios, revision } on success, { ok: false, error } otherwise)
 *
 * Example:
 * ["tf_anprc152", 7] call ace_tacphone_radio_fnc_setVolume
 *
 * Public: No
 */

params [["_radioId", ""], ["_volume", 0]];

private _radio = [_radioId] call FUNC(getRadioById);
if (isNil "_radio") exitWith {
    createHashMapFromArray [["ok", false], ["error", "radioGone"]];
};

private _isLr = _radio isEqualType [];
private _func = [TFAR_fnc_setSwVolume, TFAR_fnc_setLrVolume] select _isLr;

[_radio, _volume] call _func;

call FUNC(commitRevision);
private _snapshot = [] call FUNC(assembleAllRadios);
private _result = createHashMapFromArray [
    ["ok", true],
    ["radios", _snapshot get "radios"],
    ["revision", _snapshot get "revision"]
];

call FUNC(pushRadioState);

_result
