#include "..\script_component.hpp"
/*
 * Author: ACE Team
 * Handles requests sent by the SampleApp panel.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({"a": "SampleApp", "c": "Increment", "count": 1, "text": "Counter incremented to 1"})
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["a", "SampleApp"], ["c", "Increment"], ["count", 1], ["text", "Counter incremented to 1"]]] call ace_tacphone_SampleApp_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request"];

private _command = _request get "c";

if (isNil QGVAR(browserRequestHandlers)) then {
    private _handlers = createHashMapFromArray [
        ["Increment", {
            params ["_request"];
            private _text = _request get "text";
            private _count = _request get "count";

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

[_request] call _handler;
