#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Debug helper: finds a deep-water point near the player, spawns a boat there
 * and teleports the player to the nearest shore.
 *
 * Arguments:
 * 0: Search radius <NUMBER> (default: 3000)
 *
 * Return Value:
 * Result <HASHMAP> { ok, class, vehicle, water, player }
 *
 * Public: No
 */

params [["_searchRadius", 3000]];

if (isNull player) exitWith {
    createHashMapFromArray [["ok", false], ["error", "no player"]];
};

private _origin = getPosATL player;
private _water = [];
private _shore = [];

// exitWith only leaves the innermost block: inside a then block it does not
// break the enclosing for (verified, AGENTS/sqf.md). Every match sets a flag;
// the flat guards at loop-body level stop the scan at the first match.
for "_radius" from 100 to _searchRadius step 100 do {
    if (_water isNotEqualTo []) exitWith {};

    for "_angle" from 0 to 350 step 10 do {
        if (_water isNotEqualTo []) exitWith {};

        private _candidate = [_origin, _radius, _angle] call BIS_fnc_relPos;
        if (surfaceIsWater _candidate && {(getTerrainHeight _candidate) < -1.5}) then {
            private _land = [];
            {
                if (_land isNotEqualTo []) exitWith {};
                private _ring = _x;
                for "_shoreAngle" from 0 to 350 step 10 do {
                    if (_land isNotEqualTo []) exitWith {};
                    private _shoreCandidate = [_candidate, _ring, _shoreAngle] call BIS_fnc_relPos;
                    if (!surfaceIsWater _shoreCandidate && {(getTerrainHeight _shoreCandidate) > 0.2}) then {
                        _land = _shoreCandidate;
                    };
                };
            } forEach [25, 50, 75, 100, 150, 200];

            if (_land isNotEqualTo []) then {
                _water = _candidate;
                _shore = _land;
            };
        };
    };
};

if (_water isEqualTo [] || {_shore isEqualTo []}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "no deep water near the player"]];
};

private _boatClass = "B_Boat_Transport_01_F";
if (!isClass (configFile >> "CfgVehicles" >> _boatClass)) then {
    private _boats = ("true" configClasses (configFile >> "CfgVehicles")) select {
        getNumber (_x >> "scope") == 2
        && {_x isKindOf "Ship"}
        && {getNumber (_x >> "maxSpeed") > 0}
    };
    _boatClass = if (_boats isNotEqualTo []) then { configName (_boats select 0) } else { "" };
};

if (_boatClass == "") exitWith {
    createHashMapFromArray [["ok", false], ["error", "no boat class available"]];
};

private _boat = [_boatClass, [_water select 0, _water select 1, 0], _shore getDir _water, _shore] call FUNC(debugSpawnVehicle);

createHashMapFromArray [
    ["ok", true],
    ["class", _boatClass],
    ["vehicle", netId _boat],
    ["water", _water],
    ["player", _shore]
];
