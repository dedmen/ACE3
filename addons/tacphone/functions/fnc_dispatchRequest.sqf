#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Resolves the target app of a browser request and forwards it to that app's request processor.
 * If the processor returns a promise, the callback is called once the promise resolves.
 * If the target app is unknown, or its AppInfo entry has no usable request
 * processor, the mismatch is logged and the callback receives
 * { "ok": false, "error": "..." } instead of a processor result.
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

// The in-game hub forwards remote/LAN requests through the local pipe and tags
// them with the page they came from. Dispatch under that client id and keep
// the tag out of the app payload.
if (_data isEqualType createHashMap) then {
    private _sourceClient = _data getOrDefault ["__sourceClient", ""];
    if (_sourceClient isEqualType "" && _sourceClient != "") then {
        _clientId = _sourceClient;
        _data deleteAt "__sourceClient";
    };
};

private _appTarget = _data get "a";

// A routing bug must be visible: an unknown target, or an entry without a
// usable processor, is logged and answered with the standard error reply
// instead of silently degrading into a no-op. Both paths reply, they never
// raise a script error (the live test suites arm a ScriptError guard).
if !(_appTarget in GVAR(AppInfo)) exitWith {
    diag_log format ["[TacPhone] Unknown app target in request from client %1: %2", _clientId, _appTarget];
    [createHashMapFromArray [["ok", false], ["error", format ["unknown app: %1", _appTarget]]], _callbackArgs] call _callback;
};

private _appInfo = GVAR(AppInfo) get _appTarget;
private _processor = _appInfo get "requestprocessor";
if !(_processor isEqualType {params [];}) exitWith {
    diag_log format ["[TacPhone] App %1 has no usable request processor (request from client %2)", _appTarget, _clientId];
    [createHashMapFromArray [["ok", false], ["error", format ["app %1 has no request processor", _appTarget]]], _callbackArgs] call _callback;
};

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
