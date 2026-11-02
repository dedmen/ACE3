#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Debug helper: finds a spawnable ground vehicle whose config allows water
 * driving (`canFloat > 0`). The result is cached for the session.
 *
 * Return Value:
 * Vehicle class name <STRING> ("" when none exists)
 *
 * Public: No
 */

private _cached = missionNamespace getVariable [QGVAR(debugWaterVehicleClass), ""];
if (_cached != "" && {isClass (configFile >> "CfgVehicles" >> _cached)}) exitWith {
    _cached
};

private _classes = ("true" configClasses (configFile >> "CfgVehicles")) select {
    getNumber (_x >> "scope") == 2
    && {getNumber (_x >> "canFloat") > 0}
    && {getNumber (_x >> "maxSpeed") > 0}
    && {_x isKindOf "Car" || {_x isKindOf "Tank"} || {_x isKindOf "Motorcycle"}}
};

private _class = if (count _classes > 0) then {
    configName (_classes select 0)
} else {
    ""
};

GVAR(debugWaterVehicleClass) = _class;
_class
