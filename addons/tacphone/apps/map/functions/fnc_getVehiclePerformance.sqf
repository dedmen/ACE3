#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Collects the config and PhysX properties the web route planner needs to model vehicle speed.
 * Missing config values come back as 0; the web side treats 0 as "not set" and uses a fallback.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Vehicle config <CONFIG>
 *
 * Return Value:
 * Vehicle performance <HASHMAP>
 *
 * Example:
 * [_vehicle, configOf _vehicle] call ace_tacphone_map_fnc_getVehiclePerformance
 *
 * Public: No
 */

params ["_vehicle", "_config"];

private _bbr = boundingBoxReal _vehicle;
private _p1 = _bbr select 0;
private _p2 = _bbr select 1;

createHashMapFromArray [
    ["maxSpeedKmh", getNumber (_config >> "maxSpeed")],
    ["enginePowerKw", getNumber (_config >> "enginePower")],
    // getMass includes the vehicle's current load, so cargo weight is reflected here without a separate field.
    ["massKg", getMass _vehicle],
    ["terrainCoef", getNumber (_config >> "terrainCoef")],
    ["canFloat", getNumber (_config >> "canFloat") > 0],
    ["waterResistanceCoef", getNumber (_config >> "waterResistanceCoef")],
    ["waterSpeedCoef", getNumber (_config >> "waterSpeedCoef")],
    ["armor", getNumber (_config >> "armor")],
    ["simulation", getText (_config >> "simulation")],
    ["maxTurnAngle", getNumber (_config >> "maxTurnAngle")],
    ["turnCoef", getNumber (_config >> "turnCoef")],
    ["tankTurnForce", getNumber (_config >> "tankTurnForce")],
    ["precisionTurnCoef", getNumber (_config >> "precisionTurnCoef")],
    // boundingBoxReal is [[xmin, ymin, zmin], [xmax, ymax, zmax], radius]
    ["widthM", abs ((_p2 select 0) - (_p1 select 0))],
    ["lengthM", abs ((_p2 select 1) - (_p1 select 1))],
    ["heightM", abs ((_p2 select 2) - (_p1 select 2))]
];
