#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Handles RemoteAccess.* requests coming from the in-game web UI.
 *
 * Only the in-game browser ("local") may call this. Remote relay clients must
 * never be able to mint pairing codes, create share links or kick other peers.
 *
 * Arguments:
 * 0: Full command name, e.g. "RemoteAccess.Start" <STRING>
 * 1: Request hashmap <HASHMAP>
 *
 * Return Value:
 * Result hashmap <HASHMAP>
 *
 * Public: No
 */

params ["_command", "_request"];

private _subcommand = _command select [13]; // strip "RemoteAccess."

private _identity = GVAR(remoteIdentity);
if (isNil "_identity" || {_identity isEqualTo ""}) then {
    private _stored = profileNamespace getVariable [QGVAR(remoteIdentity), ""];
    _identity = if (isNil "_stored") then { "" } else { _stored };
    GVAR(remoteIdentity) = _identity;
};

private _call = {
    // The array form of callExtension returns [result, returnCode, errorCode].
    private _response = "arma_webhost" callExtension ["RemoteAccess", _this];
    if (_response isEqualType []) then {
        _response param [0, ""];
    } else {
        _response;
    };
};

private _ok = {
    createHashMapFromArray [["ok", true]];
};

private _error = {
    params ["_message"];
    createHashMapFromArray [["ok", false], ["error", _message]];
};

private _parse = {
    params ["_raw"];
    if (_raw isEqualType []) then {
        _raw = _raw param [0, ""];
    };
    private _parsed = fromJSON _raw;
    if (isNil "_parsed" || {!(_parsed isEqualType createHashMap)}) then {
        createHashMapFromArray [["ok", false], ["error", format ["invalid extension response: %1", _raw]]];
    } else {
        _parsed;
    };
};

switch (_subcommand) do {
    case "Start": {
        if (!(missionNamespace getVariable [QGVAR(remoteEnabled), true])) then {
            ["remote access is disabled in the CBA settings"] call _error;
        } else {
            private _host = missionNamespace getVariable [QGVAR(remoteHost), ""];
            if (_host isEqualTo "") then {
                ["remote host is not configured"] call _error;
            } else {
                [(["Start", _host, _identity] call _call)] call _parse;
            };
        };
    };

    case "Stop": {
        [(["Stop"] call _call)] call _parse;
    };

    case "Status": {
        [(["Status"] call _call)] call _parse;
    };

    case "NewCode": {
        [(["NewCode"] call _call)] call _parse;
    };

    case "ShareCreate": {
        private _ttl = _request getOrDefault ["ttlSeconds", 3600];
        if (!(_ttl isEqualType 0)) then { _ttl = 3600 };
        [(["ShareCreate", str _ttl] call _call)] call _parse;
    };

    case "ShareRevoke": {
        [(["ShareRevoke"] call _call)] call _parse;
    };

    case "Kick": {
        private _peerId = _request getOrDefault ["peerId", ""];
        if (_peerId isEqualTo "") then {
            ["missing peer id"] call _error;
        } else {
            [(["Kick", _peerId] call _call)] call _parse;
        };
    };

    case "CopyToClipboard": {
        private _text = _request getOrDefault ["text", ""];
        if (_text isEqualTo "") then {
            ["nothing to copy"] call _error;
        } else {
            // copyToClipboard does not work in multiplayer; ACE's extension does.
            private _response = "ace" callExtension ["clipboard:append", [_text + endl]];
            "ace" callExtension ["clipboard:complete", []];

            if (_response isEqualTo "") then {
                // ACE extension unavailable (single player/editor); this one works there.
                copyToClipboard _text;
            };

            call _ok;
        };
    };

    default {
        [format ["unknown remote access command: %1", _subcommand]] call _error;
    };
};
