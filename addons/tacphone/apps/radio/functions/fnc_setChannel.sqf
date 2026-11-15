#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sets the main or additional channel of a radio.
 * Protocol channels are 1..8; the TFAR setters use the base one lower.
 *
 * Arguments:
 * 0: Radio id <STRING>
 * 1: The main channel <BOOL> (false for the additional one)
 * 2: Channel <NUMBER> (1..8)
 *
 * Return Value:
 * Reply <HASHMAP> ({ ok, radios, revision } on success, { ok: false, error } otherwise)
 *
 * Example:
 * ["tf_anprc152", true, 3] call ace_tacphone_radio_fnc_setChannel
 *
 * Public: No
 */

params [["_radioId", ""], ["_isMain", true], ["_channel", 1]];

if (_channel < 1 || {_channel > 8}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "badChannel"]];
};

private _radio = [_radioId] call FUNC(getRadioById);
if (isNil "_radio") exitWith {
    createHashMapFromArray [["ok", false], ["error", "radioGone"]];
};

private _isLr = _radio isEqualType [];
private _func = [[TFAR_fnc_setAdditionalSwChannel, TFAR_fnc_setAdditionalLrChannel],
    [TFAR_fnc_setSwChannel, TFAR_fnc_setLrChannel]] select _isMain select _isLr;

// Protocol 1..8 -> TFAR base
[_radio, _channel - 1] call _func;

call FUNC(commitRevision);
private _snapshot = [] call FUNC(assembleAllRadios);
private _result = createHashMapFromArray [
    ["ok", true],
    ["radios", _snapshot get "radios"],
    ["revision", _snapshot get "revision"]
];

call FUNC(pushRadioState);

_result
