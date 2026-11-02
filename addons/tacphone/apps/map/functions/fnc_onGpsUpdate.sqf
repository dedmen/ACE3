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
 * [] call ace_tacphone_map_fnc_onGpsUpdate
 *
 * Public: No
 */

params ["_args", "_handle"];

// Cheap early-out before any data assembly, nobody is interested
private _targets = [INTEREST_GPS] call EFUNC(tacphone,getInterestClients);
if (_targets isEqualTo []) exitWith {};
if (isNull player) exitWith {};

private _update = createHashMap;
_update set ["a", "ACE_TacPhone_Map"];
_update set ["c", "GPS.Update"];
_update set ["position", getPos player];
_update set ["view", getCameraViewDirection player];
_update set ["direction", getDir player];
_update set ["speed", speed player]; // km/h, used for the speed based zoom
_update set ["velocity", velocity player]; // m/s, used for ETA and route progress

[_targets, _update] call EFUNC(tacphone,sendCommandToPhone);
