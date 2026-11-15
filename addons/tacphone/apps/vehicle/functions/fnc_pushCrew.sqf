#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Player GetInMan/GetOutMan handler, pushes a one-off Vehicle.Crew update for
 * the vehicle that was entered or left.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Role <STRING>
 * 2: Vehicle <OBJECT>
 * 3: Turret path <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * player addEventHandler ["GetInMan", ace_tacphone_vehicle_fnc_pushCrew]
 *
 * Public: No
 */

params ["_unit", "_role", "_vehicle", "_turret"];

if (isNull player) exitWith {};
if (_vehicle isEqualTo player) exitWith {};
// GetOutMan also fires this handler with the vehicle just left; the crew
// list of a vehicle the player is no longer in must not overwrite the empty
// on-foot list sent by Vehicle.Changed.
if (vehicle player isNotEqualTo _vehicle) exitWith {};

private _crew = [_vehicle] call FUNC(buildCrew);

private _update = createHashMap;
_update set ["a", "ACE_TacPhone_Vehicle"];
_update set ["c", "Vehicle.Crew"];
_update set ["crew", _crew];
// Keep the passenger poll's signature current so it does not repeat the
// same crew right after this push.
GVAR(crewSignature) = _crew apply {
    format ["%1|%2|%3", _x get "name", _x get "role", _x get "cargoIndex"]
};

[_update] call EFUNC(tacphone,sendCommandToPhone);
