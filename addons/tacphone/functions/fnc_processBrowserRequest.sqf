#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * TacPhone webbrowser sent us data to process and reply to
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "a": "AppName", "c": "CommandName", ... })
 * 1: Client id <STRING> ("local" for the in-game browser, the websocket connection id otherwise)
 * 2: Reply callback <CODE> (called with [_result, _callbackArgs]); optional, only
 *    set when the caller (dispatchRequest) supports a processor that replies itself
 * 3: Callback arguments <ARRAY> (optional)
 *
 * Return Value:
 * ANY (Usually Hashmap or Promise)
 *
 * The terrain proxy is streamed: RequestTerrainSVG registers the reply callback in
 * GVAR(pendingTerrainRequest) and returns the streaming sentinel, and every
 * ReplyRequestTerrainSVG chunk that arrives later is forwarded to that callback.
 *
 * Example:
 * [] call ace_tacphone_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request", "_clientId", "_callback", "_callbackArgs"];

// _request is { "a": "AppName", "c": "CommandName", ... }

diag_log ["request", _request, _clientId];

private _command = _request get "c";

if (_command == "GetHostLog") exitWith {
    // Extension diagnostics are only for the in-game page.
    if (_clientId != "local") exitWith {
        createHashMapFromArray [["ok", false], ["error", "forbidden"]];
    };

    private _log = GVAR(hostLog);
    GVAR(hostLog) = [];
    _log;
};

// Remote access control is in-game only. A relay client must never be able to
// mint pairing codes, create share links or kick other peers.
if ((_command find "RemoteAccess.") == 0) exitWith {
    if (_clientId != "local") exitWith {
        diag_log format ["[TacPhone] Rejected %1 from remote client %2", _command, _clientId];
        createHashMapFromArray [["ok", false], ["error", "forbidden"]];
    };

    [_command, _request] call FUNC(remoteAccess);
};

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

if (_command == "GetFile") exitWith {
    // Return a game file as text. This is the same request the websocket file server uses;
    // XEH_postInit translates its special "GetFile" extension callback into this command.
    private _path = _request getOrDefault ["path", ""];

    if (_path == "/" || {_path == ""}) then {
        // This is a file that the browser will not send us pbo prefix'ed
        _path = QPATHTOF(data\index.html);
    };

    // Browsers send forward slashes, the game filesystem wants backslashes
    _path = _path regexReplace ["\//g", "\\"];

    if (fileExists _path) then {
        loadFile _path;
    } else {
        diag_log format ["[TacPhone] GetFile: file not found: %1", _path];
        "";
    };
};

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
    // The page replies with many ReplyRequestTerrainSVG chunks (one per layer/part); each one is forwarded
    // to the requesting client through the stored callback. We never assemble them here.

    // Drop terrain contexts of transfers that were abandoned or whose client went away.
    ["", 60] call FUNC(terrainRequestCleanup);

    // Collision-free transfer id; one context per request, so concurrent transfers can't mix.
    private _uid = GVAR(terrainRequestCounter) + 1;
    GVAR(terrainRequestCounter) = _uid;

    // Register the context BEFORE telling the page, otherwise the first reply chunk could arrive too early.
    GVAR(pendingTerrainRequest) set [_uid, createHashMapFromArray [
        ["clientId", _clientId],
        ["callback", _callback],
        ["callbackArgs", _callbackArgs],
        ["created", diag_tickTime]
    ]];

    // Tell our open TacPhone instance to fetch it
    private _clientInstanceRequest = createHashMap;
    _clientInstanceRequest set ["a", "main"]; //#TODO hashmap syntax once HEMTT supports it
    _clientInstanceRequest set ["c", "RequestTerrainSVG"];
    _clientInstanceRequest set ["config", _request get "config"];
    _clientInstanceRequest set ["uid", _uid];

    private _success = ["local", _clientInstanceRequest] call ace_tacphone_fnc_sendCommandToPhone; //#TODO EFUNC?

    if (!_success) then {
        // No phone open, so no chunks will ever arrive. Answer the requesting client once with an error chunk.
        GVAR(pendingTerrainRequest) deleteAt _uid;

        private _errorReply = createHashMapFromArray [
            ["a", "main"],
            ["c", "ReplyRequestTerrainSVG"],
            ["uid", _uid],
            ["error", "in-game phone not open"]
        ];

        [_errorReply, _callbackArgs] call _callback;
    };

    // The reply is streamed through the stored callback; dispatchRequest must not send its own reply.
    createHashMapFromArray [["__tacphone_stream", true]];
};

if (_command == "ReplyRequestTerrainSVG") exitWith {
    // The in-game page produced one chunk of a previous "RequestTerrainSVG". Forward it, untouched,
    // to the client that asked. The final/error chunk drops the context.

    private _uid = _request get "uid";
    private _context = GVAR(pendingTerrainRequest) get _uid;

    if (!(_context isEqualType createHashMap)) exitWith {
        diag_log format ["[TacPhone] ReplyRequestTerrainSVG for unknown transfer %1", _uid];
        createHashMap;
    };

    private _callback = _context get "callback";
    private _callbackArgs = _context get "callbackArgs";

    // Error or final chunk: this transfer is done.
    if ((_request getOrDefault ["error", ""]) != "" || {_request getOrDefault ["last", false]}) then {
        GVAR(pendingTerrainRequest) deleteAt _uid;
    };

    [_request, _callbackArgs] call _callback;

    createHashMap; // Return empty result, the local instance doesn't care about the reply
};



if (_command == "RequestTexture") exitWith {

    // Browser wants to get a texture (This command only comes from remote browser via Websocket)
    // We cannot retrieve the image in SQF, so forward it to the in-game browser, which grabs it and sends it back.
    // The engine raises an error popup when the texture does not exist, so check the filesystem first.

    private _path = _request getOrDefault ["path", ""];

    // Browsers send paths without the leading backslash and may use forward slashes.
    // A relative path resolves from the mission directory, so also try the game-root form.
    private _checkPath = _path regexReplace ["\//g", "\\"];

    if (!fileExists _checkPath && {!fileExists ("\" + _checkPath)}) exitWith {
        diag_log format ["[TacPhone] RequestTexture: texture file not found: %1", _path];
        createHashMapFromArray [["ok", false], ["error", format ["texture file not found: %1", _path]]];
    };

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
