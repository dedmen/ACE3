#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Debug helper: reports the current radio ids, the active
 * transmission, and a live channel-base probe so the two uncertain rows of the
 * channel base table (set*Channel, do*Transmit) can be verified in game:
 * mainChannel/additionalChannel are the raw TFAR get*Channel values of the
 * first SR radio, frequencyChannel1/2 the raw getChannelFrequency values for
 * protocol channels 1 and 2.
 *
 * Return Value:
 * Debug report <HASHMAP> ({ ready, radios, tx, channelBaseProbe })
 *
 * Public: No
 */

private _radios = call FUNC(getRadioIds);

// The channel-base probe reads the first SR radio
private _probe = createHashMap;
if (!isNull player) then {
    private _srRadios = call FUNC(srRadioClasses);
    if (count _srRadios > 0) then {
        private _first = _srRadios select 0;
        _probe set ["mainChannel", _first call TFAR_fnc_getSwChannel];
        _probe set ["additionalChannel", _first call TFAR_fnc_getAdditionalSwChannel];
        _probe set ["frequencyChannel1", [_first, 1] call TFAR_fnc_getChannelFrequency];
        _probe set ["frequencyChannel2", [_first, 2] call TFAR_fnc_getChannelFrequency];
    };
};

createHashMapFromArray [
    ["ready", count _radios > 0],
    ["radios", _radios],
    ["tx", GVAR(tx)],
    ["channelBaseProbe", _probe]
]
