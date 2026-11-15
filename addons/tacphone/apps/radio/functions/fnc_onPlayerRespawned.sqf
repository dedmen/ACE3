#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Player EntityRespawned handler: the kit may have changed, end any active
 * transmission and push the new state.
 *
 * Arguments:
 * 0: Unit <OBJECT> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * addMissionEventHandler ["EntityRespawned", ace_tacphone_radio_fnc_onPlayerRespawned]
 *
 * Public: No
 */

params ["_unit"];

if (_unit != player) exitWith {};

// A respawn replaces the unit object, so the vehicle handlers installed in
// XEH_postInit are gone with the old unit; install them on the new player.
player addEventHandler ["GetInMan", FUNC(onVehicleChanged)];
player addEventHandler ["GetOutMan", FUNC(onVehicleChanged)];

["respawn"] call FUNC(stopTransmit);
call FUNC(commitRevision);
call FUNC(pushRadioState);
