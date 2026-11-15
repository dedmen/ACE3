#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * One-off cargo inventory push: builds the Vehicle.Cargo payload for the
 * player's vehicle and sends it to the phone clients while INTEREST_CARGO is
 * held. Runs on cargo interest activation (initial snapshot) and on the four
 * ACE cargo inventory change events, which fnc_onInterestChanged filters to
 * the player's vehicle.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_vehicle_fnc_pushCargo
 *
 * Public: No
 */

// Cheap early-out before any data assembly, nobody is interested
if (([INTEREST_CARGO] call EFUNC(tacphone,getInterestClients)) isEqualTo []) exitWith {};
if (isNull player) exitWith {};

private _vehicle = vehicle player;
if (isNull _vehicle) exitWith {};
if (_vehicle isEqualTo player) exitWith {}; // on foot

// The cargo list is driver-only, like the anim payload; passengers never see it
if (driver _vehicle isNotEqualTo player) exitWith {};

// The vehicle must actually carry cargo; the web hides the section otherwise
private _caps = [_vehicle] call FUNC(getCapabilities);
if (!(_caps get "hasCargo")) exitWith {};

private _update = [_vehicle] call FUNC(buildCargo);
_update set ["a", "ACE_TacPhone_Vehicle"];
_update set ["c", "Vehicle.Cargo"];

[_update] call EFUNC(tacphone,sendCommandToPhone);
