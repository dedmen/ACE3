#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Player SeatSwitchedMan handler. GetInMan/GetOutMan do not fire on a seat
 * change inside the same vehicle; this refreshes isDriver and the crew roles.
 *
 * Arguments:
 * 0: Unit 1 <OBJECT>
 * 1: Unit 2 <OBJECT>
 * 2: Vehicle <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * player addEventHandler ["SeatSwitchedMan", ace_tacphone_vehicle_fnc_onSeatSwitched]
 *
 * Public: No
 */

params ["_unit1", "_unit2", "_vehicle"];

if (isNull player) exitWith {};
if (isNull _vehicle) exitWith {};
if (vehicle player isNotEqualTo _vehicle) exitWith {};

private _update = createHashMap;
_update set ["a", "ACE_TacPhone_Vehicle"];
_update set ["c", "Vehicle.Changed"];
_update set ["inVehicle", true];
_update set ["isDriver", driver _vehicle isEqualTo player];
_update set ["vehicle", netId _vehicle];
_update set ["capabilities", [_vehicle] call FUNC(getCapabilities)];
_update set ["crew", [_vehicle] call FUNC(buildCrew)];

[_update] call EFUNC(tacphone,sendCommandToPhone);
