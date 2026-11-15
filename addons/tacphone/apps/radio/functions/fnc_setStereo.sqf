#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sets the stereo mode of the main or additional channel of a radio
 * (0 centre, 1 left, 2 right; validated by the web before sending).
 *
 * Arguments:
 * 0: Radio id <STRING>
 * 1: The main channel <BOOL> (false for the additional one)
 * 2: Mode <NUMBER> (0 | 1 | 2)
 *
 * Return Value:
 * Reply <HASHMAP> ({ ok, radios, revision } on success, { ok: false, error } otherwise)
 *
 * Example:
 * ["tf_anprc152", true, 0] call ace_tacphone_radio_fnc_setStereo
 *
 * Public: No
 */

params [["_radioId", ""], ["_isMain", true], ["_mode", 0]];

private _radio = [_radioId] call FUNC(getRadioById);
if (isNil "_radio") exitWith {
    createHashMapFromArray [["ok", false], ["error", "radioGone"]];
};

private _isLr = _radio isEqualType [];
private _func = [[TFAR_fnc_setAdditionalSwStereo, TFAR_fnc_setAdditionalLrStereo],
    [TFAR_fnc_setSwStereo, TFAR_fnc_setLrStereo]] select _isMain select _isLr;

[_radio, _mode] call _func;

call FUNC(commitRevision);
private _snapshot = [] call FUNC(assembleAllRadios);
private _result = createHashMapFromArray [
    ["ok", true],
    ["radios", _snapshot get "radios"],
    ["revision", _snapshot get "revision"]
];

call FUNC(pushRadioState);

_result
