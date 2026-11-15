#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Assembles the GetVehicle reply: identity, capabilities, crew and a current
 * anim/state snapshot built by the same payload builders as the pushes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * HASHMAP
 * On foot: { inVehicle: false, isDriver: false, vehicle: "", crew: [] }
 * In a vehicle: { inVehicle, isDriver, vehicle (netId), capabilities, crew, anim, state }
 *
 * Example:
 * [] call ace_tacphone_vehicle_fnc_getVehicleInfo
 *
 * Public: No
 */

if (isNull player) exitWith {
    createHashMapFromArray [
        ["inVehicle", false],
        ["isDriver", false],
        ["vehicle", ""],
        ["crew", []]
    ];
};

private _vehicle = vehicle player;
if (_vehicle isEqualTo player) exitWith {
    createHashMapFromArray [
        ["inVehicle", false],
        ["isDriver", false],
        ["vehicle", ""],
        ["crew", []]
    ];
};

private _result = createHashMap;
_result set ["inVehicle", true];
_result set ["isDriver", driver _vehicle isEqualTo player];
_result set ["vehicle", netId _vehicle];
_result set ["capabilities", [_vehicle] call FUNC(getCapabilities)];
_result set ["crew", [_vehicle] call FUNC(buildCrew)];
_result set ["anim", [_vehicle] call FUNC(buildAnimPayload)];
_result set ["state", [_vehicle] call FUNC(buildStatePayload)];

_result
