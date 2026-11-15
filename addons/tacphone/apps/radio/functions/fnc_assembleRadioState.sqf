#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds one RadioDevice state hashmap from a TFAR radio handle.
 * SR radios are the class string, LR radios are [object, qualifier].
 * TFAR channel values are normalised to the protocol base: -1 -> 0 (none),
 * everything else +1, so protocol channels are 1..8.
 *
 * Arguments:
 * 0: Radio handle <STRING or ARRAY> (the handle itself, called unwrapped —
 *    the body reads _this directly, because params would destructure an
 *    LR array handle down to its bare object)
 *
 * Return Value:
 * Radio state <HASHMAP> (the RadioDevice fields)
 *
 * Example:
 * "tf_anprc152" call ace_tacphone_radio_fnc_assembleRadioState
 *
 * Public: No
 */

private _radio = _this;

private _isLr = _radio isEqualType [];

private _id = [_radio] call FUNC(encodeRadioId);

private _getters = [
    [TFAR_fnc_getSwChannel, TFAR_fnc_getAdditionalSwChannel, TFAR_fnc_getSwStereo,
     TFAR_fnc_getAdditionalSwStereo, TFAR_fnc_getSwVolume, TFAR_fnc_getSwSpeakers],
    [TFAR_fnc_getLrChannel, TFAR_fnc_getAdditionalLrChannel, TFAR_fnc_getLrStereo,
     TFAR_fnc_getAdditionalLrStereo, TFAR_fnc_getLrVolume, TFAR_fnc_getLrSpeakers]
] select _isLr;
_getters params ["_getChannel", "_getAlt", "_getStereo", "_getAltStereo", "_getVolume", "_getSpeakers"];

private _frequencies = [];
for "_i" from 1 to 8 do {
    _frequencies pushBack ([_radio, _i] call TFAR_fnc_getChannelFrequency);
};

// TFAR base -> protocol: -1 (none) -> 0, 0..7 -> 1..8
private _mainChannel = _radio call _getChannel;
private _altChannel = _radio call _getAlt;
_mainChannel = if (_mainChannel == -1) then { 0 } else { _mainChannel + 1 };
_altChannel = if (_altChannel == -1) then { 0 } else { _altChannel + 1 };

// Game-supplied display name, never translated, falling back to the id when
// empty. The id is stable for the radio's lifetime (SR: the class string,
// LR: netId + qualifier), so the config read is cached per id and the hot
// path of snapshot assembly stays off the config.
private _names = GVAR(displayNames);
private _displayName = _names getOrDefault [_id, ""];
if (_displayName == "") then {
    if (_isLr) then {
        _displayName = getText (configOf (_radio select 0) >> "displayName");
    } else {
        _displayName = getText (configFile >> "CfgWeapons" >> _radio >> "displayName");
    };
    if (_displayName == "") then {
        _displayName = _id;
    };
    _names set [_id, _displayName];
};

// Live TX fields for this radio, 0/false otherwise
private _txChannel = 0;
private _txAdditional = false;
private _tx = GVAR(tx);
if (!isNil "_tx" && {(_tx get "radio") == _id}) then {
    _txChannel = _tx get "channel";
    _txAdditional = _tx get "additional";
};

createHashMapFromArray [
    ["id", _id],
    ["kind", ["sr", "lr"] select _isLr],
    ["displayName", _displayName],
    ["mainChannel", _mainChannel],
    ["altChannel", _altChannel],
    ["frequencies", _frequencies],
    ["volume", _radio call _getVolume],
    ["mainStereo", _radio call _getStereo],
    ["altStereo", _radio call _getAltStereo],
    ["speakers", _radio call _getSpeakers],
    ["txChannel", _txChannel],
    ["txAdditional", _txAdditional]
]
