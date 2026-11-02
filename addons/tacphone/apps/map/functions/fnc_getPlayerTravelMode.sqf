#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Detects the travel mode of the local player and returns it together with the vehicle performance.
 * Shared by the GetPlayerTravelMode request and the GPS.VehicleChanged push.
 *
 * Arguments:
 * None (uses the local player)
 *
 * Return Value:
 * Travel mode info <HASHMAP>
 * - mode: "foot", "ground", "boat" or "air" <STRING>
 * - vehicleClass: config class name of the vehicle, "" on foot <STRING>
 * - waterCapable: ground vehicle that floats on water <BOOL>
 * - performance: vehicle performance from FUNC(getVehiclePerformance), empty on foot <HASHMAP>
 *
 * Example:
 * [] call ace_tacphone_map_fnc_getPlayerTravelMode
 *
 * Public: No
 */

private _vehicle = vehicle player;

if (_vehicle == player) exitWith {
    createHashMapFromArray [
        ["mode", "foot"],
        ["vehicleClass", ""],
        ["waterCapable", false],
        ["performance", createHashMap]
    ];
};

private _config = configOf _vehicle;
private _className = configName _config;

private _mode =
    if (_className isKindOf "Air") then { "air" }
    else { if (_className isKindOf "Ship") then { "boat" } else { "ground" } };

// Ground vehicles can cross water when the config says they float
private _waterCapable = _mode == "ground" && {getNumber (_config >> "canFloat") > 0};

createHashMapFromArray [
    ["mode", _mode],
    ["vehicleClass", _className],
    ["waterCapable", _waterCapable],
    ["performance", [_vehicle, _config] call FUNC(getVehiclePerformance)]
];
