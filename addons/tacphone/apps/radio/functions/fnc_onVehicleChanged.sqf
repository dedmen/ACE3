#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Player GetInMan/GetOutMan handler: the kit changes with the vehicle, the
 * radio may be gone, so end any active transmission and push the new state.
 * Deferred one frame: the vehicle is not fully occupied yet when the event fires.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Role <STRING> (unused)
 * 2: Vehicle <OBJECT> (unused)
 * 3: Turret path <ARRAY> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * player addEventHandler ["GetInMan", ace_tacphone_radio_fnc_onVehicleChanged]
 *
 * Public: No
 */

params ["_unit", "_role", "_vehicle", "_turret"];

if (_unit != player) exitWith {};

[{
    ["vehicle"] call FUNC(stopTransmit);
    call FUNC(commitRevision);
    call FUNC(pushRadioState);
}, []] call CBA_fnc_execNextFrame;
