#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Unit GetInMan/GetOutMan handler, tells the phones that hold INTEREST_GPS about the new travel mode.
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
 * player addEventHandler ["GetInMan", ace_tacphone_map_fnc_onGpsVehicleChanged]
 *
 * Public: No
 */

params ["_unit", "_role", "_vehicle", "_turret"];

// Cheap early-out before any data assembly, nobody is interested
if (([INTEREST_GPS] call EFUNC(tacphone,getInterestClients)) isEqualTo []) exitWith {};

// The vehicle is not fully occupied yet when the event fires, defer one frame
[{
    // The interest can be released while we wait for the next frame
    if (([INTEREST_GPS] call EFUNC(tacphone,getInterestClients)) isEqualTo []) exitWith {};

    private _update = call FUNC(getPlayerTravelMode);
    _update set ["a", "ACE_TacPhone_Map"];
    _update set ["c", "GPS.VehicleChanged"];

    [_update] call EFUNC(tacphone,sendCommandToPhone);
}, []] call CBA_fnc_execNextFrame;
