#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * "MarkerDeleted" mission event handler, tells the phones that hold INTEREST_MARKERS to drop the marker.
 *
 * Arguments:
 * 0: Marker name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["marker_0"] call ace_tacphone_map_fnc_onMarkerDeleted
 *
 * Public: No
 */

params ["_markerName"];

// Cheap early-out before building anything, nobody is interested
private _targets = [INTEREST_MARKERS] call EFUNC(tacphone,getInterestClients);
if (_targets isEqualTo []) exitWith {};

private _clientInstanceRequest = createHashMap;
_clientInstanceRequest set ["a", "ACE_TacPhone_Map"]; //#TODO hashmap syntax once HEMTT supports it
_clientInstanceRequest set ["c", "Marker.Delete"];
_clientInstanceRequest set ["marker", _markerName];

[_targets, _clientInstanceRequest] call EFUNC(tacphone,sendCommandToPhone);
