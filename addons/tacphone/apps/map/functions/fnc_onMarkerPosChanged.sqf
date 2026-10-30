#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * "MarkerUpdated" mission event handler and "ace_markers_setMarkerPosLocal" CBA event handler,
 * pushes the changed marker to the phones that hold INTEREST_MARKERS.
 *
 * Arguments:
 * 0: Marker name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["marker_0"] call ace_tacphone_map_fnc_onMarkerPosChanged
 *
 * Public: No
 */

params ["_marker"];

//systemChat str ["pos", _this];
//systemChat str ["mkinf", _marker call TC_main_fnc_Marker_assembleMarkerInfo];
if (GVAR(ignoreMarkerUpdate)) exitWith {};

// filter invalid marker, I don't know why this happens but it does
if (markerColor _marker == "") exitWith {};

// Cheap early-out before any marker work, nobody is interested
private _targets = [INTEREST_MARKERS] call EFUNC(tacphone,getInterestClients);
if (_targets isEqualTo []) exitWith {};

private _info = _marker call FUNC(assembleMarkerInfo);

private _clientInstanceRequest = createHashMap;
_clientInstanceRequest set ["a", "ACE_TacPhone_Map"]; //#TODO hashmap syntax once HEMTT supports it
_clientInstanceRequest set ["c", "Marker.Upsert"];
_clientInstanceRequest set ["marker", _info];

[_targets, _clientInstanceRequest] call EFUNC(tacphone,sendCommandToPhone);
