#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Server entry point for requests relayed by a client. Validates the command
 * and dispatches to the matching fnc_server* handler. The queue and the roles
 * are server-authoritative, so accepted commands reply {ok, pending} and the
 * result arrives as a push; rejected commands surface as the Error push.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "a": "ACE_TacPhone_Logistics", "c": "CreateRequest", ... })
 * 1: Client id <STRING> (page client that sent the request)
 * 2: Sender <OBJECT> (player whose client relayed the request)
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["c", "GetLogisticsState"]], "local", player] call ace_tacphone_Logistics_fnc_serverHandleRequest
 *
 * Public: No
 */

params ["_request", "_clientId", "_sender"];

// Command name for the Error pushes below. Read defensively: the early-exit
// paths may see a request that is not a hashmap at all.
private _command = if (_request isEqualType createHashMap) then { _request getOrDefault ["c", ""] } else { "" };

if (!isServer) exitWith {
    private _errorPush = createHashMapFromArray [
        ["a", LOGISTICS_APP],
        ["c", "Error"],
        ["request", _command],
        ["message", "Not the server"]
    ];
    [_errorPush, [_sender]] call FUNC(serverPushAll);
    createHashMapFromArray [["ok", false], ["error", "Not the server"]]
};

if (!(_request isEqualType createHashMap)) exitWith {
    private _errorPush = createHashMapFromArray [
        ["a", LOGISTICS_APP],
        ["c", "Error"],
        ["request", _command],
        ["message", "Invalid request"]
    ];
    [_errorPush, [_sender]] call FUNC(serverPushAll);
    createHashMapFromArray [["ok", false], ["error", "Invalid request"]]
};

if (isNull _sender) exitWith {
    // The push targets nobody, but the rejected command still pushes like any other.
    private _errorPush = createHashMapFromArray [
        ["a", LOGISTICS_APP],
        ["c", "Error"],
        ["request", _command],
        ["message", "No player"]
    ];
    [_errorPush, [_sender]] call FUNC(serverPushAll);
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _result = createHashMapFromArray [["ok", false]];

#ifdef __A3_DEBUG__
// Debug commands are opt-in twice: __A3_DEBUG__ here and the mission
// allowDebug setting; the whole block compiles out in release. The gate is
// flat, before the switch, because an `exitWith` inside a case block only
// exits the case (AGENTS/sqf.md) and would lose the specific error.
private _isDebugCommand = _command in ["Debug.CreateTestRequest", "Debug.SetRole", "Debug.Reset"];

if (_isDebugCommand && {!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])}) exitWith {
    // Like every other rejection: answer the error AND push it, so the web
    // (which only sees pushes) gets the specific "debug disabled" message.
    private _errorPush = createHashMapFromArray [
        ["a", LOGISTICS_APP],
        ["c", "Error"],
        ["request", _command],
        ["message", "debug disabled"]
    ];
    [_errorPush, [_sender]] call FUNC(serverPushAll);
    createHashMapFromArray [["ok", false], ["error", "debug disabled"]]
};
#endif

switch (_command) do {
    case "GetLogisticsState": {
        // Snapshot is scoped to the requesting player; the other pushes stay
        // broadcasts by design.
        [[_sender]] call FUNC(serverPushState);
        _result set ["ok", true];
        _result set ["pending", true];
    };
    case "CreateRequest": {
        _result = [_request, _sender] call FUNC(serverCreateRequest);
    };
    case "SetRequestState": {
        _result = [_request, _sender, "worker"] call FUNC(serverSetRequestState);
    };
    case "CancelRequest": {
        // Cancel goes through the same state-change path as the progress
        // states, so the history entry and the upsert push are identical.
        // A fresh map, never the inbound request: serverSetRequestState
        // reads only requestId, state and at.
        private _cancelRequest = createHashMapFromArray [
            ["requestId", _request getOrDefault ["requestId", ""]],
            ["state", LOGISTICS_STATE_CANCELLED],
            ["at", _request getOrDefault ["at", ""]]
        ];
        _result = [_cancelRequest, _sender, "owner_or_worker"] call FUNC(serverSetRequestState);
    };
    case "SetRole": {
        _result = [_request, _sender, "", ""] call FUNC(serverSetRole);
    };
#ifdef __A3_DEBUG__
    // The allowDebug gate runs flat before the switch, so a debug-off
    // caller gets the "debug disabled" error; the per-function guards in
    // the fnc_debug* files stay as defense in depth for direct calls.
    case "Debug.CreateTestRequest": {
        _result = [_request, _sender] call FUNC(debugCreateTestRequest);
    };
    case "Debug.SetRole": {
        _result = [_request, _sender] call FUNC(debugSetRole);
    };
    case "Debug.Reset": {
        _result = [_request, _sender] call FUNC(debugReset);
    };
#endif
    default {
        _result set ["error", format ["Unknown Logistics command: %1", _command]];
    };
};

// A rejected command answers the error AND pushes it, so the web can react to
// its own pending action. The relay is fire-and-forget (the web only ever
// receives `{ok: true, pending: true}`), so the push is scoped to the
// requesting player with no interest gating (interests never reach the
// server machine, and an early-out would swallow the error on a dedicated
// server).
if (!(_result getOrDefault ["ok", false])) then {
    private _errorPush = createHashMapFromArray [
        ["a", "ACE_TacPhone_Logistics"],
        ["c", "Error"],
        ["request", _command],
        ["message", _result getOrDefault ["error", "Request failed"]]
    ];

    private _requestId = _request getOrDefault ["requestId", ""];
    if (_requestId != "") then {
        _errorPush set ["requestId", _requestId];
    };

    // Player-scoped push: broadcast to all pages of the requesting player.
    [_errorPush, [_sender]] call FUNC(serverPushAll);
};

_result
