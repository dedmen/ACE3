#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Applies the GPS update rate selected in the Map options ("gpsUpdateRate").
 * Stores the interval for the next per-frame handler start and, while the GPS
 * interest is held, restarts the running handler so the new rate applies
 * immediately.
 *
 * Arguments:
 * 0: Update rate <NUMBER> (Hz; rejected below 1 or above 60)
 *
 * Return Value:
 * Result <HASHMAP> ({ "ok", true, "hz" } or { "ok", false, "error" })
 *
 * Example:
 * [30] call ace_tacphone_map_fnc_setGpsUpdateRate
 *
 * Public: No
 */

params ["_hz"];

// The web only sends the validated 10/30 choices (sqf.md: trust web-supplied
// types), but an out-of-range value would break the interval below.
if (_hz < 1 || _hz > 60) exitWith {
    createHashMapFromArray [["ok", false], ["error", format ["invalid GPS update rate: %1", _hz]]];
};

private _interval = 1 / _hz;
GVAR(gpsUpdateInterval) = _interval;

// While the interest is held the per-frame handler is running; restart it with
// the new interval so the change does not wait for the interest to be re-held.
if (!isNil QGVAR(gpsPFH)) then {
    [GVAR(gpsPFH)] call CBA_fnc_removePerFrameHandler;
    GVAR(gpsPFH) = [FUNC(onGpsUpdate), _interval, []] call CBA_fnc_addPerFrameHandler;
};

createHashMapFromArray [["ok", true], ["hz", _hz]];
