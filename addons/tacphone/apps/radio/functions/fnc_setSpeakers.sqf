#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Enables or disables the speakers of a radio.
 * The TFAR setter is a toggle that takes no value, so the current state is read
 * first and the toggle only happens when it differs from the requested state.
 *
 * Arguments:
 * 0: Radio id <STRING>
 * 1: Speakers enabled <BOOL>
 *
 * Return Value:
 * Reply <HASHMAP> ({ ok, radios, revision } on success, { ok: false, error } otherwise)
 *
 * Example:
 * ["tf_anprc152", true] call ace_tacphone_radio_fnc_setSpeakers
 *
 * Public: No
 */

params [["_radioId", ""], ["_enabled", false]];

private _radio = [_radioId] call FUNC(getRadioById);
if (isNil "_radio") exitWith {
    createHashMapFromArray [["ok", false], ["error", "radioGone"]];
};

private _isLr = _radio isEqualType [];

// The handle is called unwrapped (as fnc_assembleRadioState does): the SR
// string is the single TFAR argument, the LR [object, qualifier] handle
// splats into TFAR's two LR arguments. Wrapping it in [_radio] would hand
// TFAR the whole array as the "radio object" and kill the script mid-reply.
if ((_radio call ([TFAR_fnc_getSwSpeakers, TFAR_fnc_getLrSpeakers] select _isLr)) != _enabled) then {
    _radio call ([TFAR_fnc_setSwSpeakers, TFAR_fnc_setLrSpeakers] select _isLr);
    // A no-op write (state already equal) leaves the revision untouched
    call FUNC(commitRevision);
};

private _snapshot = [] call FUNC(assembleAllRadios);
private _result = createHashMapFromArray [
    ["ok", true],
    ["radios", _snapshot get "radios"],
    ["revision", _snapshot get "revision"]
];

call FUNC(pushRadioState);

_result
