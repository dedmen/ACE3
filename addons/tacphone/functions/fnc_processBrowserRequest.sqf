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
 * Example:
 * [] call ace_tacphone_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request", "_clientId", "_callback", "_callbackArgs"];

// _request is { "a": "AppName", "c": "CommandName", ... }

#ifdef __A3_DEBUG__
diag_log ["request", _request, _clientId];
#endif

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

#ifdef __A3_DEBUG__
// Test-only bridges for the stored host runtime tests. They are deliberately
// separate from the RemoteAccess.* command below, which stays local-only.
// These commands are compiled only into __A3_DEBUG__ builds and additionally
// require the server-controlled "Allow debug mode" setting.
if (_command == "Debug.Status") exitWith {
    if (!(missionNamespace getVariable [QGVAR(allowDebug), false])) exitWith {
        createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
    };

    createHashMapFromArray [["ok", true], ["debug", true]];
};

if (_command == "Debug.SetLocalDisplayMode") exitWith {
    if (!(missionNamespace getVariable [QGVAR(allowDebug), false])) exitWith {
        createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
    };

    [_request getOrDefault ["mode", ""]] call FUNC(debugSetLocalDisplayMode);
};

if (_command == "Debug.GetInterests") exitWith {
    if (!(missionNamespace getVariable [QGVAR(allowDebug), false])) exitWith {
        createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
    };

    private _source = if (isNil QGVAR(AppDataInterests)) then { createHashMap } else { GVAR(AppDataInterests) };
    private _interests = createHashMap;
    {
        private _entry = _y;
        private _clients = _entry getOrDefault ["clients", createHashMap];
        _interests set [_x, keys _clients];
    } forEach _source;

    createHashMapFromArray [["ok", true], ["interests", _interests]];
};

// Send one payload to the LAN webhost clients. The in-game hub owns the
// JSON framing; SQF passes it through and returns the extension's raw response.
if (_command == "WebHost.Send") exitWith {
    if (_clientId != "local") exitWith {
        createHashMapFromArray [["ok", false], ["error", "forbidden"]];
    };

    private _payload = _request getOrDefault ["payload", ""];
    private _response = "arma_webhost" callExtension ["SendTo", [_payload]];
    if (_response isEqualType []) then {
        _response = _response param [0, ""];
    };

    _response;
};
#endif

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
            [QGVAR(clientDisconnected), [_clientId]] call CBA_fnc_localEvent;
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

if (_command == "Client.Disconnected") exitWith {
    if (_clientId != "local") exitWith {
        createHashMapFromArray [["ok", false], ["error", "forbidden"]];
    };

    private _disconnected = _request getOrDefault ["clientId", ""];
    [QGVAR(clientDisconnected), [_disconnected]] call CBA_fnc_localEvent;

    createHashMapFromArray [["ok", true]];
};

if (_command == "GetPlayerPos") exitWith { getPos player };
if (_command == "GetTime") exitWith { time };

if (_command == "GetGameInfo") exitWith {
    private _product = productVersion;
    private _versionNumber = if (count _product > 2) then { _product select 2 } else { 0 };
    private _buildNumber = if (count _product > 3) then { _product select 3 } else { 0 };
    private _gameVersion = format [
        "%1.%2.%3",
        floor (_versionNumber / 100),
        _versionNumber mod 100,
        _buildNumber
    ];

    private _debug = false;
#ifdef __A3_DEBUG__
_debug = missionNamespace getVariable [QGVAR(allowDebug), false];
#endif

    createHashMapFromArray [
        ["multiplayer", isMultiplayer],
        ["playerId", getPlayerID player],
        ["missionName", missionName],
        ["terrainName", worldName],
        ["gameVersion", _gameVersion],
        ["debug", _debug]
    ];
};

if (_command == "GetAvailableApps") exitWith { GVAR(AppInfo) };

if (_command == "Localization.Info") exitWith {
    // The web UI loads the whole stringtable through the file request path and
    // parses it in the browser; SQF only reports the language and the path.
    createHashMapFromArray [
        ["language", language],
        ["stringtable", QPATHTOF(stringtable.xml)]
    ];
};

if (_command == "Localization.Get") exitWith {
    // On-demand fallback only: used when the page could not load the file, or
    // when a key is missing from a loaded table. At most 100 localize calls.
    private _keys = _request getOrDefault ["keys", []];
    if (!(_keys isEqualType [])) then { _keys = []; };
    if (count _keys > 100) then { _keys resize 100 };

    private _strings = createHashMap;
    {
        if (_x isEqualType "") then {
            private _text = localize _x;
            // localize returns the key itself when the string is not found.
            if (_text != "" && {_text != _x}) then {
                _strings set [_x, _text];
            };
        };
    } forEach _keys;

    _strings;
};

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
    // The page gzips and base64-encodes the flexlayout model before saving it, so
    // the stored value is an opaque string. "" means no layout was saved yet.
    profileNamespace getVariable [QGVAR(layout), ""];
};

if (_command == "SaveLayout") exitWith {
    private _layout = _request getOrDefault ["layout", ""];

    // Only guard the profile from a client sending an oversized value.
    if (count _layout > 65536) exitWith {
        createHashMapFromArray [["ok", false], ["error", "layout too large"]];
    };

    // Ignore a repeated layout instead of writing the profile again.
    if (_layout isEqualTo (profileNamespace getVariable [QGVAR(layout), ""])) exitWith {
        createHashMapFromArray [["ok", true]];
    };

    profileNamespace setVariable [QGVAR(layout), _layout];
    // Deliberately no saveProfileNamespace: the game writes the profile on its own
    // and on exit anyway, and losing the last layout change is not important.

    createHashMapFromArray [["ok", true]];
};

private _result = createHashMap;
_result set ["a", "hello world"];

_result
