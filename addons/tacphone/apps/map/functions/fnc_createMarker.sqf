#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Creates or updates a marker from data sent by the TacPhone map app.
 *
 * Arguments:
 * 0: Marker data <HASHMAP>
 * 1: Update an existing marker instead of creating one <BOOL> (default: false)
 *
 * Return Value:
 * Result <HASHMAP> (contains the created marker name)
 *
 * Example:
 * [createHashMapFromArray [["position", [100, 200]], ["type", "mil_dot"], ["color", "Default"], ["label", "Marker"]]] call ace_tacphone_map_fnc_createMarker
 *
 * Public: No
 */

params [["_markerData", createHashMap], ["_isUpdate", false]];

private _markerName = _markerData getOrDefault ["name", ""];
private _channel = _markerData getOrDefault ["channel", 0];

// An update needs to know which marker to update, creating one needs a position
if (_isUpdate && {markerShape _markerName == ""}) exitWith { createHashMap };
if (!_isUpdate && {!("position" in _markerData)}) exitWith { createHashMap };

// _USER_DEFINED markers are associated with the player that created them. The format is
// _USER_DEFINED #<PlayerID>/<MarkerID>/<ChannelID>, the MarkerID only has to be unique.
if (_markerName == "") then {
    _markerName = format ["_USER_DEFINED #%1/ACE_TP%2/%3", getPlayerID player, floor (diag_tickTime * 1000), _channel];
};

private _position = _markerData getOrDefault ["position", [0, 0, 0]];
private _text = _markerData getOrDefault ["text", _markerData getOrDefault ["label", ""]];
private _type = _markerData getOrDefault ["type", "mil_dot"];
private _color = _markerData getOrDefault ["color", "Default"];
private _dir = _markerData getOrDefault ["dir", 0];
private _shape = _markerData getOrDefault ["shape", ""];
private _alpha = _markerData getOrDefault ["alpha", 1];
private _brush = _markerData getOrDefault ["brush", ""];
private _size = _markerData getOrDefault ["size", [1, 1]];
private _polyline = _markerData getOrDefault ["polyline", []];

if (!(_position isEqualTypeArray [0, 0]) && {!(_position isEqualTypeArray [0, 0, 0])}) exitWith { createHashMap };

if (_size isEqualType 0) then {
    _size = [_size, _size];
};

if (_shape == "") then {
    _shape = ["ICON", "POLYLINE"] select (_polyline isNotEqualTo []);
};

// Update existing marker
if (_isUpdate) exitWith {
    isNil { //Critical section, to prevent markerUpdated EH from spamming updates
        GVAR(ignoreMarkerUpdate) = true;

        if ("position" in _markerData) then { _markerName setMarkerPosLocal _position; };
        if ("type" in _markerData) then { _markerName setMarkerTypeLocal _type; };
        if ("color" in _markerData) then { _markerName setMarkerColorLocal _color; };
        if ("dir" in _markerData) then { _markerName setMarkerDirLocal _dir; };
        if ("shape" in _markerData || {"polyline" in _markerData}) then { _markerName setMarkerShapeLocal _shape; };
        if ("alpha" in _markerData) then { _markerName setMarkerAlphaLocal _alpha; };
        if ("brush" in _markerData) then { _markerName setMarkerBrushLocal _brush; };
        if ("size" in _markerData) then { _markerName setMarkerSizeLocal _size; };
        if ("polyline" in _markerData && {count _polyline > 3 && {count _polyline mod 2 == 0}}) then { _markerName setMarkerPolylineLocal _polyline; };

        // Even if all other properties above were Local only, this setMarkerText will transfer the whole marker state over network
        if ("text" in _markerData || {"label" in _markerData}) then {
            _markerName setMarkerText _text;
        } else {
            _markerName setMarkerText (markerText _markerName);
        };

        GVAR(ignoreMarkerUpdate) = false;
    };

    [_markerName] call FUNC(onMarkerPosChanged);

    private _result = createHashMap;
    _result set ["name", _markerName];

    _result
};

// Create new marker local first to save some network traffic
isNil { //Critical section, to prevent markerUpdated EH from spamming updates
    GVAR(ignoreMarkerUpdate) = true;

    private _marker = createMarkerLocal [_markerName, _position, _channel, player];

    _marker setMarkerTypeLocal _type;
    _marker setMarkerColorLocal _color;

    if ("dir" in _markerData) then { _marker setMarkerDirLocal _dir; };
    if (_shape != "") then { _marker setMarkerShapeLocal _shape; };
    if ("alpha" in _markerData) then { _marker setMarkerAlphaLocal _alpha; };
    if ("brush" in _markerData) then { _marker setMarkerBrushLocal _brush; };
    if ("size" in _markerData) then { _marker setMarkerSizeLocal _size; };
    if ("polyline" in _markerData && {count _polyline > 3 && {count _polyline mod 2 == 0}}) then { _marker setMarkerPolylineLocal _polyline; };

    _marker setMarkerText _text; //This last call will make it public and transfer over network

    GVAR(ignoreMarkerUpdate) = false;
};

[_markerName] call FUNC(onMarkerCreated);

private _result = createHashMap;
_result set ["name", _markerName];

_result
