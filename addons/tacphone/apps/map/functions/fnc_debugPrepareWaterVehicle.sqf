#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Debug helper: spawns a water-capable ground vehicle at the supplied road
 * position (or next to the player) and teleports the player beside it.
 *
 * Arguments:
 * 0: Spawn position <ARRAY> (optional; default: player position)
 *
 * Return Value:
 * Result <HASHMAP> { ok, class, vehicle, position, player }
 *
 * Public: No
 */

params [["_position", []]];

if (isNull player) exitWith {
    createHashMapFromArray [["ok", false], ["error", "no player"]];
};

private _class = call FUNC(debugFindWaterVehicle);
if (_class == "") exitWith {
    createHashMapFromArray [["ok", false], ["error", "no water-capable vehicle in CfgVehicles"]];
};

// Web code validates the payload; SQF trusts the array.
private _spawn = if (_position isEqualTo []) then {
    getPosATL player
} else {
    [_position select 0, _position select 1, 0]
};

if (vehicle player != player) then {
    moveOut player;
};

private _vehicle = createVehicle [_class, _spawn, [], 0, "NONE"];
_vehicle setPosATL _spawn;
_vehicle setVelocity [0, 0, 0];
_vehicle setDir (getDir player);

private _playerPosition = [_spawn, 7, (getDir player) + 90] call BIS_fnc_relPos;
if (surfaceIsWater _playerPosition) then {
    _playerPosition = _spawn;
};

player setPosATL _playerPosition;
player setDir (_playerPosition getDir _vehicle);

createHashMapFromArray [
    ["ok", true],
    ["class", _class],
    ["vehicle", netId _vehicle],
    ["position", _spawn],
    ["player", _playerPosition]
];
