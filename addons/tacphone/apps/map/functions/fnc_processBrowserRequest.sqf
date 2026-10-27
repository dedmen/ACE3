#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * TacPhone webbrowser sent us data to process and reply to
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ANY (Usually Hashmap or Promise)
 *
 * Example:
 * [] call ace_tacphone_map_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request"];

// _request is { "a": "AppName", "c": "CommandName", ... }
// AppName was already resolved, that's why we're here now

diag_log ["map request", _request];

private _command = _request get "c";

if (_command == "GetAllMarkers") exitWith
{
    //Register existing markers

    //#TODO the maximum result length here is limited by format[], which is about 8MB. Which should be enough. Alternative is to send separate messages per marker like:
    // {_x call TC_main_fnc_Marker_onMarkerCreated} forEach allMapMarkers;

    _allMarkers = allMapMarkers apply {_x call FUNC(assembleMarkerInfo)};

    private _result = createHashMap;
    _result set ["markers", _allMarkers];
    _result
};

if (_command == "CreateMarker") exitWith
{
    private _markerData = _request getOrDefault ["marker", createHashMap];

    [_markerData] call FUNC(createMarker)
};

if (_command == "GetMarkerTypes") exitWith
{
    private _markerTypes = [];

    {
        private _className = configName _x;
        private _name = getText (_x >> "name");
        private _color = getArray (_x >> "color") apply {_x call BIS_fnc_parseNumber};
        private _size = getNumber (_x >> "size");
        private _icon = getText (_x >> "icon");
        private _shadow = getNumber (_x >> "shadow");

        if (count _color < 3) then {
            // wtf? c_unknown config is broken.
            _color = [1,1,1,1];
        };

        private _markerTypeInfo = [_className, _name, _color, _size, _icon, _shadow];
        _markerTypes pushBack (_markerTypeInfo);
    } forEach ("true" configClasses (configFile >> "CfgMarkers"));

    private _markerColors = [];
    {
        private _className = configName _x;
        private _name = getText (_x >> "name");
        private _color = getArray (_x >> "color") apply {_x call BIS_fnc_parseNumber};


        private _markerTypeInfo = [_className, _name, _color];
        _markerColors pushBack (_markerTypeInfo);
    } forEach ("true" configClasses (configFile >> "CfgMarkerColors"));

    private _markerBrushes = [];
    {
        private _className = configName _x;
        private _name = getText (_x >> "name");
        private _texture = getText (_x >> "texture");
        private _drawBorder = getNumber (_x >> "drawBorder");

        private _markerTypeInfo = [_className, _name, _texture, _drawBorder];
        _markerBrushes pushBack (_markerTypeInfo);
    } forEach ("true" configClasses (configFile >> "CfgMarkerBrushes"));

    private _result = createHashMap;
    _result set ["types", _markerTypes];
    _result set ["colors", _markerColors];
    _result set ["brushes", _markerBrushes];
    _result
};




private _result = createHashMap;
_result set ["a", "hello world"];

_result
