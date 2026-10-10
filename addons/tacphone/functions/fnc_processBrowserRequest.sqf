#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * TacPhone webbrowser sent us data to process and reply to
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request"];

// _request is { "a": "AppName", "c": "CommandName", ... }

diag_log ["request", _request];

private _command = _request get "c";

if (_command == "GetPlayerPos") exitWith { getPos player };
if (_command == "GetTime") exitWith { time };
if (_command == "GetAvailableApps") exitWith { toJSON GVAR(AppInfo) };

// We proxy some requests that only the in-game webbrowser can retrieve, but that the external webbrowser wants to request



if (_command == "RequestTerrainSVG") exitWith {

    // Browser wants to get the terrain SVG image (This command only comes from remote browser via Websocket)
    // We cannot fulfill that request directly, SQF cannot retrieve the image, but the WebBrowser can
    // So we require that the TacPhone is currently open in-game, forward the request to our TacPhone Browser, let it grab the SVG, compress, base64 encode, give it back to SQF
    // Then we get it here and send it back out to the browser who wanted it

    // In case we get multiple requests with different configs, we need a unique ID
    private _uid = hashValue [systemTime, _request get "config"];

    // Tell our open TacPhone instance to fetch it

    private _clientInstanceRequest = createHashMap;
    _clientInstanceRequest set ["a", "main"]; //#TODO hashmap syntax once HEMTT supports it
    _clientInstanceRequest set ["c", "RequestTerrainSVG"];
    _clientInstanceRequest set ["config", _request get "config"];
    _clientInstanceRequest set ["uid", _uid];

    private _success = ["local", _clientInstanceRequest] call ace_tacphone_fnc_sendCommandToPhone; //#TODO EFUNC?

    _success; //#TODO check if TacPhone actually open, if not then we need to return error now


    // We cannot fulfill it now, so we send a promise which we'll resolve when we have the answer
    private _resultPromise = spawn "terrainSVGRequest";

    if (isNil QGVAR(pendingTerrainRequest)) then { GVAR(pendingTerrainRequest) = createHashMap };
    GVAR(pendingTerrainRequest) set [_uid, _resultPromise];

    _resultPromise; // Return
};

if (_command == "ReplyRequestTerrainSVG") exitWith {
    // A browser has previously requested Terrain SVG image via "RequestTerrainSVG", this is the answerr

    private _uid = _request get "uid";
    private _terrainData = _request get "data";
    private _promise = GVAR(pendingTerrainRequest) deleteAt _uid;
    //#TODO null check

    _promise terminate _terrainData; // Resolve the promise, will fire continueWith and forward the data through WebSocket to the browser who wanted it

    createHashMap; // Return empty result, the local instance doesn't care about reply
};



if (_command == "RequestTexture") exitWith {

    // Browser wants to get the terrain SVG image (This command only comes from remote browser via Websocket)
    // We cannot fulfill that request directly, SQF cannot retrieve the image, but the WebBrowser can
    // So we require that the TacPhone is currently open in-game, forward the request to our TacPhone Browser, let it grab the SVG, compress, base64 encode, give it back to SQF
    // Then we get it here and send it back out to the browser who wanted it

    // In case we get multiple requests with different configs, we need a unique ID
    private _uid = hashValue [systemTime, _request get "path", _request get "maxSize"];

    // Tell our open TacPhone instance to fetch it

    private _clientInstanceRequest = createHashMap;
    _clientInstanceRequest set ["a", "main"]; //#TODO hashmap syntax once HEMTT supports it
    _clientInstanceRequest set ["c", "RequestTexture"];
    _clientInstanceRequest set ["path", _request get "path"];
    _clientInstanceRequest set ["maxSize", _request get "maxSize"];
    _clientInstanceRequest set ["uid", _uid];

    private _success = ["local", _clientInstanceRequest] call ace_tacphone_fnc_sendCommandToPhone; //#TODO EFUNC?

    _success; //#TODO check if TacPhone actually open, if not then we need to return error now (or remember this until phone opens)


    // We cannot fulfill it now, so we send a promise which we'll resolve when we have the answer
    private _resultPromise = spawn "textureRequest";

    //#TODO own hashmap for these, doesn't really matter because they have unique IDs
    if (isNil QGVAR(pendingTerrainRequest)) then { GVAR(pendingTerrainRequest) = createHashMap };
    GVAR(pendingTerrainRequest) set [_uid, _resultPromise];

    _resultPromise; // Return
};

if (_command == "ReplyRequestTexture") exitWith {
    // A browser has previously requested Terrain SVG image via "RequestTexture", this is the answerr

    private _uid = _request get "uid";
    private _terrainData = _request get "data";
    private _promise = GVAR(pendingTerrainRequest) deleteAt _uid;
    //#TODO null check

    _promise terminate _terrainData; // Resolve the promise, will fire continueWith and forward the data through WebSocket to the browser who wanted it

    createHashMap; // Return empty result, the local instance doesn't care about reply
};






private _result = createHashMap;
_result set ["a", "hello world"];

_result
