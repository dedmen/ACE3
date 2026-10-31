#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Simulates a TacPhone display mode on the local machine without loading or
 * closing any UI. Only compiled into builds made with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Mode <STRING> ("CLOSED", "HUD", "DIALOG" or "HIDDEN")
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * ["HUD"] call ace_tacphone_Messaging_fnc_debugSetLocalDisplayMode
 *
 * Public: No
 */

params [["_mode", ""]];

private _names = ["CLOSED", "HUD", "DIALOG", "HIDDEN"];
private _index = _names find (toUpper _mode);

if (_index < 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", format ["Unknown display mode: %1", _mode]]]
};

if (!hasInterface) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No local interface"]]
};

private _modeNumber = [MESSAGING_DISPLAY_MODE_CLOSED, MESSAGING_DISPLAY_MODE_HUD, MESSAGING_DISPLAY_MODE_DIALOG, MESSAGING_DISPLAY_MODE_HIDDEN] select _index;

// Actually open/close the phone, not just flip the variable: a real HUD can
// otherwise switch the simulated mode back to HUD on the next PFH tick.
[_modeNumber] call EFUNC(tacphone,openDisplay);

createHashMapFromArray [
    ["ok", true],
    ["mode", _names select _index],
    ["modeNumber", _modeNumber]
]
#endif
