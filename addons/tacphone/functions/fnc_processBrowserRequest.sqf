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

// Remote access control is in-game only. A relay client must never be able to
// mint pairing codes, create share links or kick other peers. This is a
// prefix dispatch over many commands, so it is checked before the
// single-command handler map below.
if ((_command find "RemoteAccess.") == 0) exitWith {
    if (_clientId != "local") exitWith {
        diag_log format ["[TacPhone] Rejected %1 from remote client %2", _command, _clientId];
        createHashMapFromArray [["ok", false], ["error", "forbidden"]];
    };

    [_command, _request] call ace_tacphone_fnc_remoteAccess;
};

if (isNil QGVAR(browserRequestHandlers)) then {
    // Information interests are built-in commands of app "main". They need the client id
    // of the requesting browser to know who holds which interest.
    // "Interest.Set" and "Interest.Clear" share this handler and branch on the command.
    private _interestHandler = {
        params [["_request", []], ["_clientId", ""], "_command"];

        if (_clientId == "") then {
            diag_log format ["[TacPhone] Interest command without a client id: %1", _request];
            createHashMapFromArray [["ok", false], ["error", "invalid client id"]];
        } else {
            if (_command == "Interest.Clear") then {
                [_clientId] call ace_tacphone_fnc_interestClearClient;
                ["ace_tacphone_clientDisconnected", [_clientId]] call CBA_fnc_localEvent;
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
                    [_clientId, _interest, _active] call ace_tacphone_fnc_interestSet;
                    createHashMapFromArray [["ok", true]];
                };
            };
        };
    };

#ifdef __A3_DEBUG__
    // One-time state for Debug.Eval (below). The probe template declares the
    // ace_tacphone_eval_probe_body marker variable: the ScriptError handler
    // receives the failing script's code as a string and matches probes by
    // that token (a comment would not survive: the preprocessor strips
    // comments from the compiled code literal).
    GVAR(evalState) = createHashMap;
    GVAR(evalCounter) = 0;
    GVAR(evalProbeCode) = {
        params ["_id", "_code"];
        private _ace_tacphone_eval_probe_body = true; // marker token: the ScriptError handler (below) matches the failing script's code string by it
        missionNamespace setVariable [QGVAR(evalActiveProbe), _id];
        // A failing `compile` aborts this script (verified live), which the
        // ScriptError handler turns into the error reply; the guard covers
        // the codeNull case.
        private _compiled = compile _code;
        if !(_compiled isEqualType {}) exitWith {
            // The ScriptError handler may have already recorded the engine's
            // own text for the failing compile; keep it over the generic.
            private _entry = (GVAR(evalState)) get _id;
            if ((_entry param [0, ""]) == "") then {
                _entry set [0, "compile failed (syntax error, unknown command or comment)"];
            };
        };
        // A value-less (Nothing) result leaves _value undefined (a nil
        // initializer would not help: assigning nil undefines too), so the
        // isNil check is the only safe way to read it.
        _value = call _compiled;
        // Only clear the marker if this probe still owns it, so a probe that
        // slept cannot clobber a newer probe's entry.
        if (missionNamespace getVariable [QGVAR(evalActiveProbe), ""] isEqualTo _id) then {
            missionNamespace setVariable [QGVAR(evalActiveProbe), ""];
        };
        private _entry = GVAR(evalState) get _id;
        _entry set [1, true];
        _entry set [2, if (isNil "_value") then { nil } else { _value }];
    };
    // A failing `compile` aborts the probe script; a runtime error in the
    // user code does not (the probe continues after it). Record the engine
    // error text into the pending entry of the active probe so Debug.Eval
    // can reply with it.
    addMissionEventHandler ["ScriptError", {
        params ["_errorText", "_sourceFile", "_lineNumber", "_errorPos", "_content", "_stackTraceOutput"];
        private _id = missionNamespace getVariable [QGVAR(evalActiveProbe), ""];
        if (_id != "" && {_id in GVAR(evalState)}) then {
            private _entry = GVAR(evalState) get _id;
            private _userCode = _entry param [3, ""];
            // Ours if the failing script is the probe template (its code
            // string carries the marker token) or a frame of the probe's
            // user code (the failing expression's text is then a substring
            // of the user code). Both sides non-empty: "" is "found" at
            // position 0 of any string and would claim unrelated errors.
            if (_content find "ace_tacphone_eval_probe_body" >= 0 || {_userCode != "" && {_content != "" && {(_userCode find _content) >= 0}}}) then {
                _entry set [0, _errorText];
                missionNamespace setVariable [QGVAR(evalActiveProbe), ""];
            };
        };
        // false: keep the engine's RPT logging.
        false
    }];
#endif

    private _handlers = createHashMapFromArray [
        ["GetHostLog", {
            params [["_request", []], ["_clientId", ""]];
            // Extension diagnostics are only for the in-game page.
            if (_clientId != "local") exitWith {
                createHashMapFromArray [["ok", false], ["error", "forbidden"]];
            };

            private _log = ace_tacphone_hostLog;
            ace_tacphone_hostLog = [];
            _log
        }],
#ifdef __A3_DEBUG__
        // Test-only bridges for the stored host runtime tests. They are deliberately
        // separate from the RemoteAccess.* command above, which stays local-only.
        // These commands are compiled only into __A3_DEBUG__ builds and additionally
        // require the server-controlled "Allow debug mode" setting.
        ["Debug.Status", {
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            createHashMapFromArray [["ok", true], ["debug", true]];
        }],
        ["Debug.SetLocalDisplayMode", {
            params ["_request"];
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            [_request getOrDefault ["mode", ""]] call ace_tacphone_fnc_debugSetLocalDisplayMode;
        }],
        ["Debug.GetInterests", {
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            private _source = if (isNil "ace_tacphone_AppDataInterests") then { createHashMap } else { ace_tacphone_AppDataInterests };
            private _interests = createHashMap;
            {
                private _entry = _y;
                private _clients = _entry getOrDefault ["clients", createHashMap];
                _interests set [_x, keys _clients];
            } forEach _source;

            createHashMapFromArray [["ok", true], ["interests", _interests]];
        }],
        ["Debug.Notify.Reset", {
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            localNamespace setVariable [QGVAR(notifyTimes), []];
            createHashMapFromArray [["ok", true]];
        }],
        // Live SQF execution for the stored test probes. The code runs in a
        // fresh script so it may sleep (e.g. to let an action settle before
        // reading the result); the dispatch continueWith replies with the
        // script's exit value. Runs on the machine hosting the web host (in
        // single player: the player's machine). Compile failures, top-level
        // `exitWith` and runtime errors all reply with an explicit `error`;
        // a failing probe dies and the ScriptError mission handler (built
        // with the handler map) records the engine error text into its
        // entry. A blocking loop without sleep still freezes that machine,
        // so keep it to probes.
        // The code arrives base64-encoded in "codeB64" and is decoded here:
        // the LAN JSON pipe mangles quotes and backslashes in raw text, but
        // the base64 alphabet survives it intact, so the tool no longer has
        // a backslash-free or quote-free probe constraint. "code" (raw text)
        // is kept for manual in-game console calls.
        ["Debug.Eval", {
            params ["_request"];
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            private _codeB64 = _request getOrDefault ["codeB64", ""];
            private _code = if (_codeB64 isEqualType "" && _codeB64 != "") then {
                controlNull ctrlWebBrowserAction ["FromBase64", _codeB64];
            } else {
                _request getOrDefault ["code", ""];
            };
            if (_code isEqualType "" && _code == "") exitWith {
                createHashMapFromArray [["ok", false], ["error", "missing code"]];
            };

            [_code] spawn {
                params ["_code"];

                // The body runs inside `call`: a spawned script exits valueless
                // when an `exitWith { <value> }` ends it (the dispatch
                // continueWith would then see the script's args array), but
                // the `call` returns the `exitWith` value, which as the
                // script's last statement becomes its exit value.
                call {
                    // State entry: [engine error text, value set, exit value, user code].
                    GVAR(evalCounter) = GVAR(evalCounter) + 1;
                    private _id = format ["eval_%1", GVAR(evalCounter)];
                    GVAR(evalState) set [_id, ["", false, objNull, _code]];

                    // The probe (GVAR(evalProbeCode), built with the handler map)
                    // compiles and calls the code. A failing `compile` or a
                    // runtime error in the code is recorded into the entry by
                    // the ScriptError handler, so this script can still reply
                    // with the engine error text.
                    private _probe = [_id, _code] spawn GVAR(evalProbeCode);

                    waitUntil { scriptDone _probe };

                    private _entry = GVAR(evalState) get _id;
                    GVAR(evalState) deleteAt _id;

                    private _error = _entry param [0, ""];
                    // The engine aborts the frame when a valueless call
                    // result is consumed (fires when the probed code's final
                    // statement is a variable assignment: "GIAS/GIAR pre
                    // stack size violation"); report it as the probe ending
                    // without a value instead of the raw engine text.
                    if (_error find "stack size violation" >= 0) then {
                        _error = "probe exited without a value (its final statement is an assignment; end the probe with the value expression you want back)";
                    };
                    if (_error != "") exitWith {
                        createHashMapFromArray [["ok", false], ["error", _error]];
                    };
                    if (!(_entry param [1, false])) exitWith {
                        createHashMapFromArray [["ok", false], ["error", "probe exited without a value (top-level exitWith)"]]
                    };

                    // A value-less probe result is stored as nil, which leaves
                    // _value undefined on the assignment; isNil catches it.
                    _value = _entry param [2];
                    if (isNil "_value") exitWith {
                        createHashMapFromArray [["ok", true], ["result", nil], ["text", "Null"]]
                    };
                    // Objects survive the JSON pipe only as text; `result` comes
                    // back null for them.
                    createHashMapFromArray [
                        ["ok", true],
                        ["result", _value],
                        ["text", if (_value isEqualType "") then { _value } else { str _value }]
                    ]
                }
            }
        }],
        // Send one payload to the LAN webhost clients. The in-game hub owns the
        // JSON framing; SQF passes it through and returns the extension's raw response.
        ["WebHost.Send", {
            params [["_request", []], ["_clientId", ""]];
            if (_clientId != "local") exitWith {
                createHashMapFromArray [["ok", false], ["error", "forbidden"]];
            };

            private _payload = _request getOrDefault ["payload", ""];
            private _response = "arma_webhost" callExtension ["SendTo", [_payload]];
            if (_response isEqualType []) then {
                _response = _response param [0, ""];
            };

            _response
        }],
#endif
        ["Interest.Set", _interestHandler],
        ["Interest.Clear", _interestHandler],
        ["Client.Disconnected", {
            params [["_request", []], ["_clientId", ""]];
            if (_clientId != "local") exitWith {
                createHashMapFromArray [["ok", false], ["error", "forbidden"]];
            };

            private _disconnected = _request getOrDefault ["clientId", ""];

            // The peer's interests are per-client state; drop them before the
            // apps get the disconnect event, like the webhost pipe does.
            if (_disconnected != "") then {
                [_disconnected] call ace_tacphone_fnc_interestClearClient;
            };

            ["ace_tacphone_clientDisconnected", [_disconnected]] call CBA_fnc_localEvent;

            createHashMapFromArray [["ok", true]];
        }],
        ["Notify.Show", {  params ["_request"]; [_request] call FUNC(notifyShow) }],
        ["GetPlayerPos", { getPos player }],
        ["GetTime", { time }],
        ["GetGameInfo", {
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
            _debug = missionNamespace getVariable ["ace_tacphone_allowDebug", false];
#endif
            createHashMapFromArray [
                ["multiplayer", isMultiplayer],
                // Session-local DirectPlay id ("0" in singleplayer, "-1" for
                // non-players); the Map filters own markers with it.
                ["playerId", getPlayerID player],
                // Stable account id (SteamID64; "_SP_PLAYER_" in singleplayer,
                // "" for non-players). A different namespace from playerId: the
                // web keys every UID comparison (ownership, roles) on this one.
                ["playerUid", getPlayerUID player],
                ["missionName", missionName],
                ["terrainName", worldName],
                ["gameVersion", _gameVersion],
                ["debug", _debug]
            ];
        }],
        ["GetAvailableApps", {
            // The stored list keeps each app's request code, which cannot be
            // serialized to JSON; return a copy without it.
            private _apps = +ace_tacphone_AppInfo;

            {
                _y deleteAt "requestprocessor";
            } forEach _apps;

            _apps
        }],
        ["Localization.Info", {
            // The whole stringtable is bundled into index.html at build time; SQF
            // only reports the language and the path.
            createHashMapFromArray [
                ["language", language],
                ["stringtable", "z\ace\addons\tacphone\stringtable.xml"]
            ];
        }],
        ["Localization.Get", {
            params ["_request"];
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

            _strings
        }],
        ["GetFile", {
            params ["_request"];
            // Return a game file as text. This is the same request the websocket file server uses;
            // XEH_postInit translates its special "GetFile" extension callback into this command.
            private _path = _request getOrDefault ["path", ""];

            if (_path == "/" || {_path == ""}) then {
                // This is a file that the browser will not send us pbo prefix'ed
                _path = "z\ace\addons\tacphone\data\index.html";
            };

            // Browsers send forward slashes, the game filesystem wants backslashes
            _path = _path regexReplace ["\//g", "\\"];

            if (fileExists _path) then {
                loadFile _path;
            } else {
                diag_log format ["[TacPhone] GetFile: file not found: %1", _path];
                "";
            };
        }],
        ["GetLayout", {
            // The page gzips and base64-encodes the flexlayout model before saving it, so
            // the stored value is an opaque string. "" means no layout was saved yet.
            profileNamespace getVariable ["ace_tacphone_layout", ""];
        }],
        ["SaveLayout", {
            params ["_request"];
            private _layout = _request getOrDefault ["layout", ""];

            // Only guard the profile from a client sending an oversized value.
            if (count _layout > 65536) exitWith {
                createHashMapFromArray [["ok", false], ["error", "layout too large"]];
            };

            // Ignore a repeated layout instead of writing the profile again.
            if (_layout isEqualTo (profileNamespace getVariable ["ace_tacphone_layout", ""])) exitWith {
                createHashMapFromArray [["ok", true]];
            };

            profileNamespace setVariable ["ace_tacphone_layout", _layout];
            // Deliberately no saveProfileNamespace: the game writes the profile on its own
            // and on exit anyway, and losing the last layout change is not important.

            createHashMapFromArray [["ok", true]];
        }]
    ];

    GVAR(browserRequestHandlers) = compileFinal _handlers;
    // Canary: if this never appears in the RPT after the first browser request,
    // the function file did not parse cleanly at load (check the RPT for
    // "Error in expression" entries naming this file).
    diag_log ["[TacPhone] browser request handlers ready"];
};

// `get` returns an empty array for missing keys, so check the key itself.
if (!(_command in GVAR(browserRequestHandlers))) exitWith {
    diag_log format ["[TacPhone] Unknown browser command: %1", _command];
    createHashMapFromArray [["ok", false], ["error", format ["unknown command: %1", _command]]];
};

private _handler = (GVAR(browserRequestHandlers)) get _command;

[_request, _clientId, _command] call _handler;
