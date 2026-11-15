#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * TacPhone webbrowser sent us data to process and reply to
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "a": "AppName", "c": "CommandName", ... })
 * 1: Client id <STRING> ("local" for the in-game page, the websocket connection id otherwise)
 *
 * Return Value:
 * ANY (Usually Hashmap or Promise)
 *
 * Example:
 * [createHashMapFromArray [["a", "ACE_TacPhone_Radio"], ["c", "GetState"]], "local"] call ace_tacphone_radio_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request", "_clientId"];

// _request is { "a": "AppName", "c": "CommandName", ... }
// AppName was already resolved, that's why we're here now

private _command = _request get "c";

// _clientId is the originating page: "local" for the in-game browser, the
// websocket connection id for relayed requests (the dispatch layer resolves
// the hub's __sourceClient tag before the app sees the request). The app
// uses it for the per-client options and push floors, and FUNC(transmit)
// requires the radios interest to be held by it, which is what makes an
// interest release a stop signal.

if (isNil QGVAR(browserRequestHandlers)) then {
    private _handlers = createHashMapFromArray [
        ["GetState", {
            params ["_request", "_clientId"];
            // The payload may carry the per-client options; store them before replying
            private _pushMs = (_request getOrDefault ["pushMs", 250]) max 100 min 2000;
            GVAR(pushMsByClient) set [_clientId, _pushMs];

            private _options = createHashMap;
            _options set ["allowRemoteTransmit", _request getOrDefault ["allowRemoteTransmit", true]];
            _options set ["notifyRemoteTransmit", _request getOrDefault ["notifyRemoteTransmit", true]];
            GVAR(options) set [_clientId, _options];

            private _snapshot = [_pushMs] call FUNC(assembleAllRadios);

            createHashMapFromArray [
                ["ok", true],
                ["ready", _snapshot get "ready"],
                ["radios", _snapshot get "radios"],
                ["tx", _snapshot get "tx"],
                ["revision", _snapshot get "revision"],
                ["pushMs", _pushMs]
            ]
        }],
        ["SetChannel", {
            params ["_request"];
            [
                _request getOrDefault ["radioId", ""],
                _request getOrDefault ["main", true],
                _request getOrDefault ["channel", 1]
            ] call FUNC(setChannel);
        }],
        ["SetFrequency", {
            params ["_request"];
            [
                _request getOrDefault ["radioId", ""],
                _request getOrDefault ["channel", 1],
                _request getOrDefault ["frequency", 0]
            ] call FUNC(setFrequency);
        }],
        ["SetVolume", {
            params ["_request"];
            [
                _request getOrDefault ["radioId", ""],
                _request getOrDefault ["volume", 0]
            ] call FUNC(setVolume);
        }],
        ["SetStereo", {
            params ["_request"];
            [
                _request getOrDefault ["radioId", ""],
                _request getOrDefault ["main", true],
                _request getOrDefault ["mode", 0]
            ] call FUNC(setStereo);
        }],
        ["SetSpeakers", {
            params ["_request"];
            [
                _request getOrDefault ["radioId", ""],
                _request getOrDefault ["enabled", false]
            ] call FUNC(setSpeakers);
        }],
        ["Transmit", {
            params ["_request", "_clientId"];
            [
                _request getOrDefault ["radioId", ""],
                _request getOrDefault ["channel", 1],
                _request getOrDefault ["additional", false],
                _request getOrDefault ["active", true],
                _request getOrDefault ["token", ""],
                _clientId
            ] call FUNC(transmit);
        }],
        ["StopTransmit", {
            params ["_request"];
            private _token = _request getOrDefault ["token", ""];

            // An empty token forces; a given token must match the active
            // transmission. Top-level exit: nested in the `then` block it would
            // only exit the block, and a stale stop would kill the live tx.
            private _tx = GVAR(tx);
            if (_token != "" && {isNil "_tx" || {(_tx get "token") != _token}}) exitWith {
                createHashMapFromArray [["ok", true], ["stopped", false]];
            };

            private _stopped = [] call FUNC(stopTransmit);
            createHashMapFromArray [["ok", true], ["stopped", _stopped]]
        }]
#ifdef __A3_DEBUG__
        ,
        ["Radio.Debug.State", {
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            call FUNC(debugRadioState);
        }],
        ["Radio.Debug.Transmit", {
            params ["_request"];
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            private _active = _request getOrDefault ["active", true];
            private _token = _request getOrDefault ["token", "debug"];

            if (_active) exitWith {
                [
                    _request getOrDefault ["radioId", ""],
                    _request getOrDefault ["channel", 1],
                    false,
                    true,
                    _token,
                    "local"
                ] call FUNC(transmit);
            };

            ["debug"] call FUNC(stopTransmit);
            createHashMapFromArray [["ok", true], ["stopped", true]]
        }],
        ["Radio.Debug.Tangent", {
            params ["_request"];
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            // Fires the tangent handler directly, no TFAR transmission: the
            // in-game PTT mirror in both directions for the banner checks
            private _radioId = _request getOrDefault ["radioId", ""];
            private _radio = [_radioId] call FUNC(getRadioById);
            if (isNil "_radio") exitWith {
                createHashMapFromArray [["ok", false], ["error", "radioGone"]];
            };

            [player, _radio, "", false, _request getOrDefault ["active", true]] call FUNC(onTfarTangent);
            createHashMapFromArray [["ok", true]]
        }]
#endif
    ];

    GVAR(browserRequestHandlers) = compileFinal _handlers;
};

private _handler = (GVAR(browserRequestHandlers)) get _command;
if (isNil "_handler") exitWith {
    diag_log format ["[TacPhone] Unknown Radio command: %1", _command];
    createHashMapFromArray [["ok", false], ["error", format ["unknown command: %1", _command]]];
};

[_request, _clientId] call _handler;
