#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sets the frequency of one channel of a radio. The channel is used as-is
 * (1..8), like the TacControl reference. The frequency is rounded to the
 * one decimal TFAR stores and must sit inside the radio's band (SR 30..512,
 * LR 30..87 MHz); the reply re-reads the state from TFAR.
 *
 * Arguments:
 * 0: Radio id <STRING>
 * 1: Channel <NUMBER> (1..8)
 * 2: Frequency in MHz <NUMBER>
 *
 * Return Value:
 * Reply <HASHMAP> ({ ok, radios, revision } on success, { ok: false, error } otherwise)
 *
 * Example:
 * ["tf_anprc152", 3, 43.5] call ace_tacphone_radio_fnc_setFrequency
 *
 * Public: No
 */

params [["_radioId", ""], ["_channel", 1], ["_frequency", 0]];

if (_channel < 1 || {_channel > 8}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "badChannel"]];
};

private _frequency = parseNumber _frequency;
if (_frequency <= 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "badFrequency"]];
};

private _radio = [_radioId] call FUNC(getRadioById);
if (isNil "_radio") exitWith {
    createHashMapFromArray [["ok", false], ["error", "radioGone"]];
};

// TFAR only stores one decimal (TFAR_FREQ_ROUND_POWER 10) and accepts per-kind
// bands only: SR 30..512, LR (ASIP) 30..87 (TFAR defines.hpp, no per-radio
// config override). The kind follows the handle: SR radios are class strings,
// LR radios are [object, qualifier] arrays.
_frequency = round (_frequency * 10) / 10;
private _maxFrequency = [512, 87] select (_radio isEqualType []);
if (_frequency < 30 || {_frequency > _maxFrequency}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "frequencyOutOfRange"]];
};

// TFAR stores channel frequencies as strings; the game dialog only displays
// them as numbers, so a Number in the slot breaks it (ctrlSetText type error)
[_radio, _channel, str _frequency] call TFAR_fnc_setChannelFrequency;

call FUNC(commitRevision);
private _snapshot = [] call FUNC(assembleAllRadios);
private _result = createHashMapFromArray [
    ["ok", true],
    ["radios", _snapshot get "radios"],
    ["revision", _snapshot get "revision"]
];

call FUNC(pushRadioState);

_result
