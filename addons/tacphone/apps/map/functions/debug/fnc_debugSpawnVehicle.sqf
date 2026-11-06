#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Shared spawn sequence for Debug.PrepareBoat and Debug.PrepareWaterVehicle:
 * kicks the player out of their vehicle, spawns the given class at the given
 * position facing _vehicleDir and teleports the player to _playerPosition
 * facing the vehicle.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Vehicle position <ARRAY> (ATL)
 * 2: Vehicle dir <NUMBER>
 * 3: Player position <ARRAY> (ATL)
 *
 * Return Value:
 * Vehicle <OBJECT>
 *
 * Public: No
 */

params ["_class", "_vehiclePosition", "_vehicleDir", "_playerPosition"];

if (vehicle player != player) then {
    moveOut player;
};

private _vehicle = createVehicle [_class, _vehiclePosition, [], 0, "NONE"];
_vehicle setPosATL _vehiclePosition;
_vehicle setVelocity [0, 0, 0];
_vehicle setDir _vehicleDir;

player setPosATL _playerPosition;
player setDir (_playerPosition getDir _vehicle);

_vehicle
