#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Send data to the currently open TacPhone instance(s)
 *
 * Arguments:
 * 0: Target(s) <STRING or ARRAY of STRING>
 *    "local" sends to the in-game client instance,
 *    a websocket connection id sends to that specific remote browser instance,
 *    "*" sends to everyone (in-game instance plus a single broadcast to all remote clients),
 *    an array mixes any of those, e.g. ["local", "3f1c...-websocket-id"]. Empty and duplicate entries are dropped.
 * 1: The message to be sent <HASHMAP>. Must be of structure { a: "appName", c: "command", ... }
 *
 * Return Value:
 * Delivered to at least one target <BOOL>. False if the in-game phone is not open and no remote target got the message.
 *
 * Example:
 * ["*", createHashMapFromArray [["a", "main"], ["c", "SomeCommand"]]] call ace_tacphone_fnc_sendCommandToPhone
 * [["local", "3f1c2b7e-9d4a-4f7c-9d1e-5a6b7c8d9e0f"], createHashMapFromArray [["a", "ACE_TacPhone_Map"], ["c", "Marker.Upsert"]]] call ace_tacphone_fnc_sendCommandToPhone
 *
 * Public: No
 */

params [["_target", ""], ["_message", createHashMap]];

// Normalize into "send to in-game instance" plus the set of remote targets.
// "*" collapses to a single wildcard target, the extension expands it (never expand it here).
private _sendLocal = false;
private _sendAll = false;
private _remoteTargets = [];

private _targets = [];
if (_target isEqualType "") then {
    _targets = [_target];
} else {
    if (_target isEqualType []) then {
        _targets = _target;
    };
};

{
    if ((_x isEqualType "") && {_x != ""}) then {
        if (_x == "local") then {
            _sendLocal = true;
        } else {
            if (_x == "*") then {
                _sendAll = true;
            } else {
                if (!(_x in _remoteTargets)) then {
                    _remoteTargets pushBack _x;
                };
            };
        };
    };
} forEach _targets;

if (_sendAll) then {
    _sendLocal = true;
    _remoteTargets = ["*"];
};

private _localSent = false;

if (_sendLocal) then {
    // Send to local phone instance
    private _browserControl = uiNamespace getVariable [QGVAR(appSection), controlNull];

    if (!isNull _browserControl) then {
        private _messageB64 = toJSON _message; // JSON string
        _messageB64 = controlNull ctrlWebBrowserAction ["ToBase64", _messageB64];
        _browserControl ctrlWebBrowserAction ["ExecJS", format ["window.Networking.OnMessageFromGame(JSON.parse(atob('%1')))", _messageB64]];
        _localSent = true;
    };
};

if (_remoteTargets isEqualTo []) exitWith { _localSent };

// Send to remote instance(s) connected via WebSocket. One call, the JSON content stays the last argument.
private _wrapped = createHashMap;
_wrapped set ["k", "command"]; // Tell Networking.ts NetworkingWebsocket.constructor onmessage, that this is a message from game
_wrapped set ["d", _message]; // Tell Networking.ts NetworkingWebsocket.constructor onmessage, that this is a message from game

private _json = toJSON _wrapped; // JSON once, reused for every target
private _response = "arma_webhost" callExtension ["SendTo", _remoteTargets + [_json]];

// Extension answers "OK <delivered> <requested>", older builds answer just "OK".
// callExtension is called with the array syntax, which returns an array; element 0 is the result string.
private _status = if (_response isEqualType []) then { _response param [0, ""] } else { _response };
private _delivered = 0;

private _statusParts = _status splitString " ";

if ((_statusParts param [0, ""]) == "OK") then {
    _delivered = if (count _statusParts > 1) then { parseNumber (_statusParts select 1) } else { count _remoteTargets };
};

_localSent || (_delivered > 0)
