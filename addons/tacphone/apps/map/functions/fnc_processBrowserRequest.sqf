#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * TacPhone webbrowser sent us data to process and reply to
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "a": "AppName", "c": "CommandName", ... })
 * 1: Client id <STRING> (unused by this app, provided to every request processor)
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

private _command = _request get "c";

if (isNil QGVAR(browserRequestHandlers)) then {
    private _handlers = createHashMapFromArray [
        ["GetAllMarkers", {
            //Register existing markers

            //#TODO the maximum result length here is limited by format[], which is about 8MB. Which should be enough. Alternative is to send separate messages per marker like:
            private _allMarkers = allMapMarkers apply {_x call ace_tacphone_Map_fnc_assembleMarkerInfo};

            private _result = createHashMap;
            _result set ["markers", _allMarkers];
            _result
        }],
        ["GetMarkerChannels", {
            call ace_tacphone_Map_fnc_getMarkerChannels
        }],
        ["getTerrainHeight", {
            params ["_request"];
            // Heights above sea level for the requested 2D positions, in the same order.
            private _positions = _request getOrDefault ["positions", []];
            _positions apply { getTerrainHeight _x };
        }],
        ["GetPlayerTravelMode", {
            // Current travel mode of the local player plus the vehicle performance for the speed model
            call ace_tacphone_Map_fnc_getPlayerTravelMode
        }],
        ["SetGpsUpdateRate", {
            params ["_request"];
            // The Map's "gpsUpdateRate" option (Hz); always sent by the web.
            [_request get "hz"] call ace_tacphone_Map_fnc_setGpsUpdateRate
        }],
#ifdef __A3_DEBUG__
        ["Debug.PrepareBoat", {
            params ["_request"];
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            private _radius = _request getOrDefault ["searchRadius", 3000];
            [_radius] call ace_tacphone_Map_fnc_debugPrepareBoat;
        }],
        ["Debug.PrepareWaterVehicle", {
            params ["_request"];
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            [_request getOrDefault ["position", []]] call ace_tacphone_Map_fnc_debugPrepareWaterVehicle
        }],
        ["Debug.FindWaterVehicle", {
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            createHashMapFromArray [["ok", true], ["class", call ace_tacphone_Map_fnc_debugFindWaterVehicle]];
        }],
#endif
        ["CreateMarker", {
            params ["_request"];
            private _markerData = _request getOrDefault ["marker", createHashMap];

            // A name that already exists means the app wants to update that marker (e.g. after dragging it).
            // Otherwise the create path runs and generates a new name.
            private _markerName = _markerData getOrDefault ["name", ""];
            private _isUpdate = markerShape _markerName != "";

            [_markerData, _isUpdate] call ace_tacphone_Map_fnc_createMarker
        }],
        ["GetMarkerTypes", {
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

                if (_size == 0) then {
                    continue; // "Empty" marker for example
                };

                private _markerTypeInfo = [_className, _name, _color, _size, _icon, _shadow];
                _markerTypes pushBack (_markerTypeInfo);
            } forEach ("getNumber (_x >> 'scope') > 0" configClasses (configFile >> "CfgMarkers"));

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
        }],
        ["DeleteMarker", {
            params ["_request"];
            private _markerName = _request getOrDefault ["marker", ""];

            // Engine broadcasts the deletion for networked/player created markers,
            // the markerDeleted EH then pushes Marker.Delete to the phones
            deleteMarker _markerName;

            private _result = createHashMap;
            _result set ["deleted", true];
            _result set ["name", _markerName];

            _result
        }]
    ];

    GVAR(browserRequestHandlers) = compileFinal _handlers;
};

// `get` returns an empty array for missing keys, so check the key itself.
if (!(_command in GVAR(browserRequestHandlers))) exitWith {
    diag_log format ["[TacPhone] Unknown Map command: %1", _command];
    createHashMapFromArray [["ok", false], ["error", format ["unknown command: %1", _command]]];
};

private _handler = (GVAR(browserRequestHandlers)) get _command;

[_request] call _handler;
