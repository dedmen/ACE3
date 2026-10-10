#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * #TODO
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ARRAY
 *
 * Example:
 * [] call ace_tacphone_map_fnc_onMarkerPosChanged
 *
 * Public: No
 */

params ["_markerName"];

private _clientInstanceRequest = createHashMap;
_clientInstanceRequest set ["a", "ACE_TacPhone_Map"]; //#TODO hashmap syntax once HEMTT supports it
_clientInstanceRequest set ["c", "Marker.Delete"];
_clientInstanceRequest set ["marker", _markerName];

// Tell everyone //#TODO only clients that are actually interested in map updates? Though the browser discarding messages is more performance friendly than trying to figure that out here
private _success = ["*", _clientInstanceRequest] call ace_tacphone_fnc_sendCommandToPhone; //#TODO EFUNC?
