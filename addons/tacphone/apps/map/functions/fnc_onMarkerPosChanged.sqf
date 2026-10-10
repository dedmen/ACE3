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

params ["_marker"];

//systemChat str ["pos", _this];
//systemChat str ["mkinf", _marker call TC_main_fnc_Marker_assembleMarkerInfo];
if (GVAR(ignoreMarkerUpdate)) exitWith {};

// filter invalid marker, I don't know why this happens but it does
if (markerColor _marker == "") exitWith {};

private _info = _marker call FUNC(assembleMarkerInfo);

private _clientInstanceRequest = createHashMap;
_clientInstanceRequest set ["a", "ACE_TacPhone_Map"]; //#TODO hashmap syntax once HEMTT supports it
_clientInstanceRequest set ["c", "Marker.Upsert"];
_clientInstanceRequest set ["marker", _info];

// Tell everyone //#TODO only clients that are actually interested in map updates? Though the browser discarding messages is more performance friendly than trying to figure that out here
private _success = ["*", _clientInstanceRequest] call ace_tacphone_fnc_sendCommandToPhone; //#TODO EFUNC?
