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

if (_command == "Increment") exitWith {
    private _text = _request get "text";
    private _count = _request get "count";

    // Show the same text the phone notification used.
    hint _text;
    systemChat _text;

    private _result = createHashMap;
    _result set ["ok", true];
    _result set ["count", _count];
    _result
};

private _result = createHashMap;
_result set ["ok", false];
_result set ["error", format ["Unknown SampleApp command: %1", _command]];
_result
