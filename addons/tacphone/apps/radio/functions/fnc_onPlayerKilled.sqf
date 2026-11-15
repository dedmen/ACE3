#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Player EntityKilled handler: the player died, end any active transmission
 * and push the new state.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Killer <OBJECT> (unused)
 * 2: Instigator <OBJECT> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * addMissionEventHandler ["EntityKilled", ace_tacphone_radio_fnc_onPlayerKilled]
 *
 * Public: No
 */

params ["_unit", "_killer", "_instigator"];

if (_unit != player) exitWith {};

["dead"] call FUNC(stopTransmit);
call FUNC(commitRevision);
call FUNC(pushRadioState);
