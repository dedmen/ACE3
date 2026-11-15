#include "..\script_component.hpp"
/*
 * Author: ACE Team
 * Handles requests sent by the SampleApp panel.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({"a": "SampleApp", "c": "Increment", "count": 1, "text": "Counter incremented to 1"})
 * 1: Client id <STRING> ("local" in-game, a WebSocket id remotely). The framework's
 *    only hook for rejecting remote clients: `if (_clientId != "local") exitWith {...}`.
 * 2: Result callback <CODE> (called with [_result, _callbackArgs])
 * 3: Callback arguments <ARRAY> (default: [])
 *
 * The dispatcher calls processors with all four arguments,
 * [_request, _clientId, _callback, _callbackArgs] call (fnc_dispatchRequest).
 * Args 2-3 enable deferred or repeated replies: call
 * [_result, _callbackArgs] call _callback, then return the streaming sentinel
 * { "__tacphone_stream": true } so the dispatcher does not send an empty reply.
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["a", "SampleApp"], ["c", "Increment"], ["count", 1], ["text", "Counter incremented to 1"]]] call ace_tacphone_SampleApp_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request", ["_clientId", "local"], ["_callback", {}], ["_callbackArgs", []]];

private _command = _request get "c";

if (isNil QGVAR(browserRequestHandlers)) then {
    private _handlers = createHashMapFromArray [
        ["Increment", {
            params ["_request"];
            // Optional fields read through getOrDefault: `get` returns an empty
            // array for a missing key, and `hint`/`systemChat` would ScriptError
            // on it (the in-game client always sends both, a LAN copy may not).
            private _text = _request getOrDefault ["text", ""];
            private _count = _request getOrDefault ["count", 0];

            hint _text;
            systemChat _text;

            private _result = createHashMap;
            _result set ["ok", true];
            _result set ["count", _count];

            _result
        }]
    ];

    GVAR(browserRequestHandlers) = compileFinal _handlers;
};

// `get` returns an empty array for missing keys, so check the key itself.
if (!(_command in GVAR(browserRequestHandlers))) exitWith {
    diag_log format ["[TacPhone] Unknown SampleApp command: %1", _command];
    createHashMapFromArray [["ok", false], ["error", format ["unknown command: %1", _command]]];
};

private _handler = (GVAR(browserRequestHandlers)) get _command;

// The other direction (game -> phone) is a push, gated on a data interest so
// the game only assembles data while some client holds it. See XEH_postInit.sqf
// for the CBA handlers and the root README, "Data interests":
//
// if (["SampleApp.counter"] call ace_tacphone_fnc_getInterestClients isNotEqualTo []) then {
//     [createHashMapFromArray [
//         ["a", "SampleApp"],
//         ["c", "CounterUpdate"],
//         ["count", 0]
//     ]] call ace_tacphone_fnc_sendCommandToPhone; // -> Bool; the hub broadcasts to every web client
// };

[_request] call _handler;
