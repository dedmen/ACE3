#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sets the frequency of one channel of a radio. The channel is used as-is
 * (1..8), like the TacControl reference. The frequency is a plain decimal
 * string, written straight through to TFAR: the web validates the shape
 * (one decimal, inside the radio's band) before sending, and no numeric
 * check belongs on this side.
 *
 * Arguments:
 * 0: Radio id <STRING>
 * 1: Channel <NUMBER> (1..8)
 * 2: Frequency in MHz <STRING> (plain decimal, one decimal place)
 *
 * Return Value:
 * Reply <HASHMAP> ({ ok, radios, revision } on success, { ok: false, error } otherwise)
 *
 * Example:
 * ["tf_anprc152", 3, "43.5"] call ace_tacphone_radio_fnc_setFrequency
 *
 * Public: No
 */

params [["_radioId", ""], ["_channel", 1], ["_frequency", ""]];

if (_channel < 1 || {_channel > 8}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "badChannel"]];
};

private _radio = [_radioId] call FUNC(getRadioById);
if (isNil "_radio") exitWith {
    createHashMapFromArray [["ok", false], ["error", "radioGone"]];
};

// The frequency goes to TFAR as the web sent it: TFAR stores channel
// frequencies as strings (a Number in the slot breaks the game dialog),
// rounds to one decimal on store and knows its own bands.
[_radio, _channel, _frequency] call TFAR_fnc_setChannelFrequency;

call FUNC(commitRevision);
private _snapshot = [] call FUNC(assembleAllRadios);
private _result = createHashMapFromArray [
    ["ok", true],
    ["radios", _snapshot get "radios"],
    ["revision", _snapshot get "revision"]
];

call FUNC(pushRadioState);

_result
