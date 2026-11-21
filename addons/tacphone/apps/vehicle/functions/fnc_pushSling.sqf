#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Per-frame sling scope update, running at SLING_UPDATE_INTERVAL while a
 * client holds INTEREST_SLING. Pushes the 5 Hz Vehicle.Sling payload to the
 * phones.
 *
 * Arguments:
 * 0: PFH arguments <ARRAY> (unused)
 * 1: PFH handle <NUMBER> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_vehicle_fnc_pushSling
 *
 * Public: No
 */

params ["_args", "_handle"];

// Cheap early-out before any data assembly, nobody is interested
if (([INTEREST_SLING] call EFUNC(tacphone,getInterestClients)) isEqualTo []) exitWith {};
if (isNull player) exitWith {};

private _vehicle = vehicle player;
if (isNull _vehicle) exitWith {};
if (_vehicle isEqualTo player) exitWith {};
if (driver _vehicle isNotEqualTo player) exitWith {};

private _update = [_vehicle] call FUNC(buildSlingPayload);
_update set ["a", "ACE_TacPhone_Vehicle"];
_update set ["c", "Vehicle.Sling"];

[_update] call EFUNC(tacphone,sendCommandToPhone);
