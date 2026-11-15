#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Player EntityRespawned mission handler. A respawn replaces the player's
 * unit object, so the unit event handlers installed in XEH_postInit (and the
 * crew handlers installed with the anim interest) die with the old unit.
 * Reinstall the vehicle-change handlers on the new player and reset the crew
 * handler map so the next anim interest activation re-registers it.
 *
 * Arguments:
 * 0: Unit <OBJECT> (the respawned unit)
 *
 * Return Value:
 * None
 *
 * Example:
 * addMissionEventHandler ["EntityRespawned", ace_tacphone_vehicle_fnc_onPlayerRespawned]
 *
 * Public: No
 */

params ["_unit"];

if (_unit != player) exitWith {};

// A drop in flight can no longer be confirmed by the new unit
if (!isNil QGVAR(airdropActive)) then {
    ["cancelled", GVAR(airdropActive), 0, "vehicle changed"] call FUNC(pushAirdrop);
    GVAR(airdropActive) = nil;
};

// Install on the new player object; the old unit's handlers are gone with it.
player addEventHandler ["GetInMan", FUNC(onVehicleChanged)];
player addEventHandler ["GetOutMan", FUNC(onVehicleChanged)];
player addEventHandler ["SeatSwitchedMan", FUNC(onSeatSwitched)];

// The crew handlers live on the old unit; the stored map is stale and the
// activation branch's isNil guard would never re-register them.
GVAR(crewEventHandlers) = nil;
