#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Handles RemoteAccess.* requests coming from the in-game web UI.
 *
 * Only the in-game browser ("local") may call this. Remote relay clients must
 * never be able to mint pairing codes, create share links or kick other peers.
 *
 * SQF is only a transport pipe for the native relay: it opens/closes the
 * WebSocket, forwards opaque strings and stores the opaque auth identity. All
 * relay protocol state lives in the in-game Web UI.
 *
 * Arguments:
 * 0: Full command name, e.g. "RemoteAccess.Start" <STRING>
 * 1: Request hashmap <HASHMAP>
 *
 * Return Value:
 * Command specific result <ANY>
 *
 * Public: No
 */

params ["_command", "_request"];

private _subcommand = _command select [13]; // strip "RemoteAccess."

private _ok = {
    createHashMapFromArray [["ok", true]];
};

private _error = {
    params ["_message"];
    createHashMapFromArray [["ok", false], ["error", _message]];
};

private _stripTrailingSlash = {
    params ["_value"];

    while {(count _value) > 0 && {(_value select [(count _value) - 1]) == "/"}} do {
        _value = _value select [0, (count _value) - 1];
    };

    _value;
};

// Accepts a bare host, an http(s) URL or a ws(s) URL.
// Returns [webBase, websocketUrl] or [] when the host is empty/invalid.
// The path is the WebSocket path; an empty path means "/ws".
private _parseHost = {
    params ["_host"];

    _host = trim _host;
    if (_host isEqualTo "") exitWith { [] };

    private _scheme = "wss";
    private _rest = _host;
    private _schemeEnd = _host find "://";

    if (_schemeEnd != -1) then {
        _scheme = toLower (_host select [0, _schemeEnd]);
        _rest = _host select [_schemeEnd + 3];
    };

    if !(_scheme in ["http", "https", "ws", "wss"]) exitWith { [] };

    private _fragment = _rest find "#";
    if (_fragment != -1) then { _rest = _rest select [0, _fragment] };

    private _query = _rest find "?";
    if (_query != -1) then { _rest = _rest select [0, _query] };

    private _pathStart = _rest find "/";
    private _authority = if (_pathStart == -1) then { _rest } else { _rest select [0, _pathStart] };
    if (_authority isEqualTo "") exitWith { [] };

    private _path = if (_pathStart == -1) then { "" } else { _rest select [_pathStart] };
    _path = [_path] call _stripTrailingSlash;
    if (_path isEqualTo "") then { _path = "/ws" };

    private _secure = (_scheme == "https" || {_scheme == "wss"});
    private _webScheme = if (_secure) then { "https" } else { "http" };
    private _wsScheme = if (_secure) then { "wss" } else { "ws" };

    [
        format ["%1://%2", _webScheme, _authority],
        format ["%1://%2%3", _wsScheme, _authority, _path]
    ]
};

private _closeRelay = {
    private _handle = localNamespace getVariable [QGVAR(relayHandle), "gone"];

    if (_handle isNotEqualTo "gone") then {
        webRequest createHashMapFromArray [
            ["type", "close"],
            ["connection", _handle]
        ];
    };

    localNamespace setVariable [QGVAR(relayHandle), "gone"];
};

switch (_subcommand) do {
    case "Start": {
        if (!(missionNamespace getVariable [QGVAR(remoteEnabled), true])) exitWith {
            ["remote access is disabled in the CBA settings"] call _error;
        };

        private _host = missionNamespace getVariable [QGVAR(remoteHost), ""];
        private _parsed = [_host] call _parseHost;

        if (_parsed isEqualTo []) exitWith {
            ["remote host is not configured"] call _error;
        };

        _parsed params ["_webBase", "_wsUrl"];

        // Invalidate callbacks of an existing connection before replacing it.
        GVAR(relayGeneration) = GVAR(relayGeneration) + 1;
        call _closeRelay;

        GVAR(relayArmed) = true;
        GVAR(relayUrl) = _wsUrl;
        GVAR(relayWebBase) = _webBase;
        private _handle = webRequest createHashMapFromArray [
            ["type", "websocket"],
            ["url", _wsUrl],
            ["origin", "arma://ACE_TacPhone"],
            ["callbackContext", GVAR(relayGeneration)],
            ["onWebsocketEstablished", {
                if (_thisArgs != GVAR(relayGeneration)) exitWith {};

                private _control = uiNamespace getVariable [QGVAR(appSection), controlNull];
                if (isNull _control) exitWith {};

                _control ctrlWebBrowserAction ["ExecJS", "window.TacPhone.networking.OnRelayEvent('established')"];
            }],
            ["onWebsocketDataReceived", {
                if (_thisArgs != GVAR(relayGeneration)) exitWith {};
                params ["_request", "_data"];

                [_data] call FUNC(forwardTransportMessage);
            }],
            ["onWebsocketLost", {
                if (_thisArgs != GVAR(relayGeneration)) exitWith {};

                localNamespace setVariable [QGVAR(relayHandle), "gone"];

                private _control = uiNamespace getVariable [QGVAR(appSection), controlNull];
                if (isNull _control) exitWith {};

                _control ctrlWebBrowserAction ["ExecJS", "window.TacPhone.networking.OnRelayEvent('lost')"];
            }]
        ];

        localNamespace setVariable [QGVAR(relayHandle), _handle];

        createHashMapFromArray [
            ["ok", true],
            ["webBase", _webBase]
        ];
    };

    case "Stop": {
        GVAR(relayGeneration) = GVAR(relayGeneration) + 1;
        GVAR(relayArmed) = false;
        GVAR(relayUrl) = "";
        GVAR(relayWebBase) = "";

        call _closeRelay;

        call _ok;
    };

    case "Forward": {
        private _data = _request getOrDefault ["data", ""];
        private _handle = localNamespace getVariable [QGVAR(relayHandle), "gone"]; // Cannot use isNull on a handle, so we do this

        private _result = if (
            !(GVAR(relayArmed))
            || _handle isEqualTo "gone"
        ) then {
            // A savegame load nulls the handle without firing onWebsocketLost.
            // Tell the hub so it can clear peers and reconnect.
            if (GVAR(relayArmed)) then {
                GVAR(relayArmed) = false;
                GVAR(relayGeneration) = GVAR(relayGeneration) + 1;

                private _control = uiNamespace getVariable [QGVAR(appSection), controlNull];
                if (!isNull _control) then {
                    _control ctrlWebBrowserAction ["ExecJS", "window.TacPhone.networking.OnRelayEvent('lost')"];
                };
            };

            ["relay is not connected"] call _error
        } else {
            webRequest createHashMapFromArray [
                ["type", "send"],
                ["connection", _handle],
                ["data", _data]
            ];

            call _ok
        };

        _result
    };

    case "GetAuthIdentity": {
        profileNamespace getVariable [QGVAR(remoteIdentity), ""];
    };

    case "SetAuthIdentity": {
        private _identity = _request getOrDefault ["identity", ""];
        if (!(_identity isEqualType "")) then { _identity = "" };

        GVAR(remoteIdentity) = _identity;
        profileNamespace setVariable [QGVAR(remoteIdentity), _identity];
        saveProfileNamespace;

        call _ok;
    };

    case "CopyToClipboard": {
        private _text = _request getOrDefault ["text", ""];
        if (_text isEqualTo "") exitWith {
            ["nothing to copy"] call _error;
        };

        // copyToClipboard does not work in multiplayer; ACE's extension does.
        private _response = "ace" callExtension ["clipboard:append", [_text + endl]];
        "ace" callExtension ["clipboard:complete", []];

        if (_response isEqualTo "") then {
            // ACE extension unavailable (single player/editor); this one works there.
            copyToClipboard _text;
        };

        call _ok;
    };

    default {
        [format ["unknown remote access command: %1", _subcommand]] call _error;
    };
};
