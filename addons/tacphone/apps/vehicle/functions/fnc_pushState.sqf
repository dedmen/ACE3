#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Per-frame attitude update, running at STATE_UPDATE_INTERVAL while a client
 * holds INTEREST_STATE. Pushes the 20 Hz Vehicle.State payload to the phones.
 *
 * Arguments:
 * 0: PFH arguments <ARRAY> (unused)
 * 1: PFH handle <NUMBER> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_vehicle_fnc_pushState
 *
 * Public: No
 */

params ["_args", "_handle"];

// Cheap early-out before any data assembly, nobody is interested
if (([INTEREST_STATE] call EFUNC(tacphone,getInterestClients)) isEqualTo []) exitWith {};
if (isNull player) exitWith {};

private _vehicle = vehicle player;
if (isNull _vehicle) exitWith {};
if (_vehicle isEqualTo player) exitWith {};
if (driver _vehicle isNotEqualTo player) exitWith {};

private _update = [_vehicle] call FUNC(buildStatePayload);
_update set ["a", "ACE_TacPhone_Vehicle"];
_update set ["c", "Vehicle.State"];

[_update] call EFUNC(tacphone,sendCommandToPhone);
