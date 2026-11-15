#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Per-frame GPS update, running at GPS_UPDATE_INTERVAL while a client holds INTEREST_GPS.
 * Pushes the local player position, view and movement to the phones that show the GPS.
 *
 * Arguments:
 * 0: PFH arguments <ARRAY> (unused)
 * 1: PFH handle <NUMBER> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_Map_fnc_onGpsUpdate
 *
 * Public: No
 */

params ["_args", "_handle"];

// Cheap early-out before any data assembly, nobody is interested
if (([INTEREST_GPS] call EFUNC(tacphone,getInterestClients)) isEqualTo []) exitWith {};
if (isNull player) exitWith {};

// A respawn replaces player while the interest stays held: the GetInMan/
// GetOutMan handlers armed on the old unit never fire for the new one, so
// travel-mode updates would silently stop after death. Re-arm them here;
// the check is one variable read and an identity compare per tick. This also
// covers a player that was still null when the interest was activated.
private _armedUnit = GVAR(gpsVehicleEventUnit);
if (!(_armedUnit isEqualTo player)) then {
    private _oldHandlers = GVAR(gpsVehicleEventHandlers);
    if (!isNil "_oldHandlers" && {!isNil "_armedUnit"} && {!isNull _armedUnit}) then {
        {
            _armedUnit removeEventHandler [_x, _y];
        } forEach _oldHandlers;
    };

    private _handlers = createHashMap;

    _handlers set ["GetInMan", player addEventHandler ["GetInMan", FUNC(onGpsVehicleChanged)]];
    _handlers set ["GetOutMan", player addEventHandler ["GetOutMan", FUNC(onGpsVehicleChanged)]];

    GVAR(gpsVehicleEventHandlers) = _handlers;
    GVAR(gpsVehicleEventUnit) = player;
};

private _update = createHashMap;
_update set ["a", "ACE_TacPhone_Map"];
_update set ["c", "GPS.Update"];
_update set ["position", getPos player];
_update set ["view", getCameraViewDirection player];
_update set ["direction", getDir player];
_update set ["speed", speed player]; // km/h, used for the speed based zoom
_update set ["velocity", velocity player]; // m/s, used for ETA and route progress

[_update] call EFUNC(tacphone,sendCommandToPhone);
