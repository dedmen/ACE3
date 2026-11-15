#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Debug-only state dump for the live test suite.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * HASHMAP { inVehicle, isDriver, class }
 *
 * Example:
 * [] call ace_tacphone_vehicle_fnc_debugVehicleInfo
 *
 * Public: No
 */

if (isNull player) exitWith {
    createHashMapFromArray [
        ["inVehicle", false],
        ["isDriver", false],
        ["class", ""]
    ];
};

private _vehicle = vehicle player;
if (_vehicle isEqualTo player) exitWith {
    createHashMapFromArray [
        ["inVehicle", false],
        ["isDriver", false],
        ["class", ""]
    ];
};

createHashMapFromArray [
    ["inVehicle", true],
    ["isDriver", driver _vehicle isEqualTo player],
    ["class", typeOf _vehicle]
]
