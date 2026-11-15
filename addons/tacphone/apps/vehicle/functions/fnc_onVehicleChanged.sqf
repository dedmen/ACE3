#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Player GetInMan/GetOutMan event handler: the engine fires it with
 * [unit, role, vehicle, turret(, isEject)] whenever the player boards or
 * dismounts a vehicle - via moveInXXXX/moveOut, the GetInXXXX/GetOut actions
 * or a key press. Pushes the one-off Vehicle.Changed update, which is the
 * phone UI's source of truth for in-vehicle state.
 *
 * Arguments:
 * 0: Unit <OBJECT> (the player's unit)
 * 1: Role <STRING> ("driver", "gunner", "commander" or "cargo")
 * 2: Vehicle <OBJECT> (vehicle entered on GetInMan, vehicle left on GetOutMan)
 * 3: Turret path <ARRAY>
 * 4: isEject <BOOL> (GetOutMan only, Arma 3 v2.14+)
 *
 * Return Value:
 * None
 *
 * Example:
 * player addEventHandler ["GetInMan", ace_tacphone_vehicle_fnc_onVehicleChanged]
 *
 * Public: No
 */

params ["_unit", "_role", "_vehicle", "_turret", ["_isEject", false]];

if (isNull player) exitWith {};

private _update = createHashMap;
_update set ["a", "ACE_TacPhone_Vehicle"];
_update set ["c", "Vehicle.Changed"];

// On a GetOutMan the player is now on foot and the argument names the vehicle
// left; on a GetInMan the argument is the vehicle entered, i.e. vehicle player.
if (vehicle player isNotEqualTo _vehicle) exitWith {
    // A drop in flight cannot survive the dismount
    if (!isNil QGVAR(airdropActive)) then {
        ["cancelled", GVAR(airdropActive), 0, "vehicle changed"] call FUNC(pushAirdrop);
        GVAR(airdropActive) = nil;
    };

    GVAR(crewSignature) = nil;
    GVAR(wheelsBrake) = false;

    _update set ["inVehicle", false];
    _update set ["isDriver", false];
    _update set ["vehicle", ""];
    _update set ["crew", []];

    [_update] call EFUNC(tacphone,sendCommandToPhone);
};

// The cache is keyed by vehicle netId; a new vehicle must never read stale flags.
GVAR(capabilityCache) = createHashMap;
GVAR(crewSignature) = nil;
GVAR(wheelsBrake) = false;

// A drop in flight cannot survive the vehicle change
if (!isNil QGVAR(airdropActive)) then {
    ["cancelled", GVAR(airdropActive), 0, "vehicle changed"] call FUNC(pushAirdrop);
    GVAR(airdropActive) = nil;
};

_update set ["inVehicle", true];
_update set ["isDriver", driver _vehicle isEqualTo player];
_update set ["vehicle", netId _vehicle];
_update set ["capabilities", [_vehicle] call FUNC(getCapabilities)];
// No crew here (O5): the Vehicle.Crew push that follows the same
// GetInMan/GetOutMan event is the one-off crew source, and the 0.5 Hz poll
// in fnc_pushAnim keeps it live while the anim interest is held.

[_update] call EFUNC(tacphone,sendCommandToPhone);
