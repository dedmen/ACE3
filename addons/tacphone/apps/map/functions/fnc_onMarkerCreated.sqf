#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * "MarkerCreated" mission event handler, pushes the new marker to the phones that hold INTEREST_MARKERS.
 *
 * Arguments:
 * 0: Marker name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["marker_0"] call ace_tacphone_map_fnc_onMarkerCreated
 *
 * Public: No
 */
params ["_markerName"];

// Cheap early-out before any marker work, nobody is interested
private _targets = [INTEREST_MARKERS] call EFUNC(tacphone,getInterestClients);
if (_targets isEqualTo []) exitWith {};

//After ACE marker edit, the direction/angle isn't set yet when this is called
[{
    params ["_markerName"];

    // filter invalid marker, I don't know why this happens but it does
    if (markerColor _markerName == "") exitWith {};

    // The interest can be released while we wait for the next frame
    private _targets = [INTEREST_MARKERS] call EFUNC(tacphone,getInterestClients);
    if (_targets isEqualTo []) exitWith {};

    private _info = _markerName call FUNC(assembleMarkerInfo);

    private _clientInstanceRequest = createHashMap;
    _clientInstanceRequest set ["a", "ACE_TacPhone_Map"]; //#TODO hashmap syntax once HEMTT supports it
    _clientInstanceRequest set ["c", "Marker.Upsert"];
    _clientInstanceRequest set ["marker", _info];

    [_targets, _clientInstanceRequest] call EFUNC(tacphone,sendCommandToPhone);

}, _markerName] call CBA_fnc_execNextFrame;
