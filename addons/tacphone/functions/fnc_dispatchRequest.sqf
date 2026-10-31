#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Resolves the target app of a browser request and forwards it to that app's request processor.
 * If the processor returns a promise, the callback is called once the promise resolves.
 *
 * Arguments:
 * 0: Request data <HASHMAP> ({ "a": "AppName", "c": "CommandName", ... })
 * 1: Client id <STRING> ("local" for the in-game browser, the websocket connection id otherwise)
 * 2: Result callback <CODE> (called with [_result, _callbackArgs])
 * 3: Callback arguments <ARRAY> (default: [])
 *
 * The processor is called with the optional arguments 2 and 3 as well:
 * [_data, _clientId, _callback, _callbackArgs] call _processor.
 * Existing processors that only declare ["_request", "_clientId"] simply ignore them.
 * A processor may reply on its own, more than once, or later; it then returns the
 * streaming sentinel hashmap ["__tacphone_stream" -> true] and this function does not
 * send a reply itself.
 *
 * Return Value:
 * None
 *
 * Example:
 * [_request, "local", {params ["_result", "_args"]; systemChat str _result;}, []] call ace_tacphone_fnc_dispatchRequest
 *
 * Public: No
 */
params ["_data", "_clientId", "_callback", ["_callbackArgs", []]];

// _data is { "a": "AppName", "c": "CommandName", ... }
private _appTarget = _data get "a";

if !(_appTarget in GVAR(AppInfo)) then {
    diag_log ["Unknown App via command", _appTarget];
};

private _appInfo = GVAR(AppInfo) getOrDefaultCall [_appTarget, {createHashMap}]; //#TODO log error if not found
private _processor = _appInfo getOrDefaultCall ["requestprocessor", {"UNKNOWN HANDLER in request process"}]; //#TODO log error if not found

private _result = [_data, _clientId, _callback, _callbackArgs] call _processor; // Forward to that app's specific processor

if (_result isEqualType scriptNull) exitWith {
    // The script sent a promise as result, we don't yet have the data to send back
    _result continueWith [{
        _thisArgs params ["_callback", "_callbackArgs"];
        [_this, _callbackArgs] call _callback;
    }, [_callback, _callbackArgs]];
};

// Streaming sentinel: the processor already replied (possibly multiple times, over
// several requests). Do not send another, empty reply.
if ((_result isEqualType createHashMap) && {_result getOrDefault ["__tacphone_stream", false]}) exitWith {};

[_result, _callbackArgs] call _callback;
