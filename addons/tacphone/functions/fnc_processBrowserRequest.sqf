#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * TacPhone webbrowser sent us data to process and reply to
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "a": "AppName", "c": "CommandName", ... })
 * 1: Client id <STRING> ("local" for the in-game browser, the websocket connection id otherwise)
 *
 * Return Value:
 * ANY (Usually Hashmap or Promise)
 *
 * Example:
 * [] call ace_tacphone_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request", "_clientId"];

// _request is { "a": "AppName", "c": "CommandName", ... }

diag_log ["request", _request, _clientId];

private _command = _request get "c";

// Information interests are built-in commands of app "main". They need the client id
// of the requesting browser to know who holds which interest.
if (_command == "Interest.Set" || {_command == "Interest.Clear"}) exitWith {
    if (_clientId == "") then {
        diag_log format ["[TacPhone] Interest command without a client id: %1", _request];
        createHashMapFromArray [["ok", false], ["error", "invalid client id"]];
    } else {
        if (_command == "Interest.Clear") then {
            [_clientId] call FUNC(interestClearClient);
            createHashMapFromArray [["ok", true]];
        } else {
            private _interest = _request getOrDefault ["interest", ""];
            private _active = _request getOrDefault ["active", false];

            if (_interest == "") then {
                diag_log format ["[TacPhone] Invalid Interest.Set interest name from client %1: %2", _clientId, _request];
                createHashMapFromArray [["ok", false], ["error", "invalid interest name"]];
            } else {
                // A false return only means "nothing changed" (duplicate set, or removing an
                // interest the client did not hold). That is still a successful request.
                [_clientId, _interest, _active] call FUNC(interestSet);
                createHashMapFromArray [["ok", true]];
            };
        };
    };
};

if (_command == "GetPlayerPos") exitWith { getPos player };
if (_command == "GetTime") exitWith { time };
if (_command == "GetAvailableApps") exitWith { GVAR(AppInfo) };

if (_command == "GetLayout") exitWith {
    //#TODO Return the phone layout persisted in-game once layout saving via "SaveLayout" is implemented.
    createHashMap;
};

if (_command == "SaveLayout") exitWith {
    //#TODO Store the layout received in _request get "layout" so "GetLayout" can return it later.
    createHashMap;
};

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
