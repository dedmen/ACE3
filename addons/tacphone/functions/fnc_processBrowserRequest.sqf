#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * TacPhone webbrowser sent us data to process and reply to
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request"];

private _command = _request get "c";

if (_command == "GetPlayerPos") exitWith { getPos player };
if (_command == "GetTime") exitWith { time };

private _result = createHashMap;
_result set ["a", "hello world"];

_result
