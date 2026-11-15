#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Moves an open request to a new state through the single shared path used by
 * both SetRequestState (requirement "worker") and CancelRequest (requirement
 * "owner_or_worker", the caller injects "cancelled" as the state).
 *
 * Appends the history entry, sets the state and pushes the upsert, so a cancel
 * and a progress change produce identical records. Resending the state the
 * request is already in is a no-op ({ok: true}, no history entry, no upsert).
 * After the upsert, the closed history is pruned to
 * LOGISTICS_CLOSED_HISTORY_CAP (fnc_serverPruneRequests): only a transition
 * to done/cancelled can add a closed record, and terminals are final.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "SetRequestState"|"CancelRequest", "requestId": "", "state": "" })
 * 1: Sender <OBJECT> (player changing the state)
 * 2: Requirement <STRING> ("worker" or "owner_or_worker")
 *
 * Return Value:
 * Result <HASHMAP> ({ok: true, pending: true} on success, {ok: true} for an
 * unchanged state, {ok: false, error} on rejection)
 *
 * Example:
 * [_request, player, "worker"] call ace_tacphone_Logistics_fnc_serverSetRequestState
 *
 * Public: No
 */

params ["_request", "_sender", ["_requirement", "worker"]];

if (isNull _sender) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _requestId = _request getOrDefault ["requestId", ""];
private _record = GVAR(serverRequests) getOrDefault [_requestId, createHashMap];

if (count _record == 0) exitWith {
    createHashMapFromArray [["ok", false], ["error", "request gone"]]
};

// Open = not done/cancelled. Both terminals are final.
private _state = _record getOrDefault ["state", ""];

if (_state == LOGISTICS_STATE_DONE || {_state == LOGISTICS_STATE_CANCELLED}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "already closed"]]
};

// Cancellation only happens through the owner/worker path; the progress
// states are the five values short of "cancelled".
private _newState = _request getOrDefault ["state", ""];

// JSON strings arrive as SQF strings; `str` would wrap the value in quotes.
if !(_newState isEqualType "") then {
    _newState = "";
};

// Guards must be flat top-level statements of the function body: an
// `exitWith` nested inside an if/else branch only exits the branch block
// (see AGENTS/sqf.md), so a nested guard silently never rejects.
private _valid = false;
if (_requirement == "owner_or_worker") then {
    _valid = (_newState == LOGISTICS_STATE_CANCELLED);
} else {
    _valid = (_newState in [LOGISTICS_STATE_QUEUED, LOGISTICS_STATE_PACKING, LOGISTICS_STATE_WAITING_DELIVERY, LOGISTICS_STATE_DELIVERING, LOGISTICS_STATE_DONE]);
};
if (!_valid) exitWith {
    createHashMapFromArray [["ok", false], ["error", "invalid state"]]
};

private _uid = getPlayerUID _sender;
private _isWorker = (GVAR(serverRoles) getOrDefault [_uid, ""]) == "worker";
private _requesterUid = _record getOrDefault ["requesterUid", ""];
private _allowed = false;
if (_requirement == "owner_or_worker") then {
    if (_isWorker || {_uid == _requesterUid}) then {
        _allowed = true;
    };
} else {
    if (_isWorker) then {
        _allowed = true;
    };
};
if (!_allowed) exitWith {
    private _error = "workers only";
    if (_requirement == "owner_or_worker") then {
        _error = "not your request";
    };
    createHashMapFromArray [["ok", false], ["error", _error]]
};

// The UI only fires on a real change, but a custom client may resend the
// state the request is already in: that is a no-op, not a change, so it
// gets ok without a history entry and without the upsert.
if (_newState == _state) exitWith {
    createHashMapFromArray [["ok", true]]
};

// M-1: the history `at` is a client-stamped UTC epoch seconds string; it is
// kept only when it is a sane epoch (10 digits, 1e9..4e9), mirroring the
// `created` validator in fnc_serverCreateRequest (regexMatch, not `str`:
// `str` renders an epoch in scientific notation). An invalid value is stored
// as "" (the web renders the time placeholder); the entry is still appended.
private _isEpoch = {
    params ["_value"];
    if !(_value isEqualType "") exitWith { false };
    private _n = parseNumber _value;
    (_n >= 1000000000) && {_n <= 4000000000} && {_value regexMatch '[0-9]{10}'}
};
private _at = _request getOrDefault ["at", ""];
if !([_at] call _isEpoch) then {
    _at = "";
};

// The history array is stored by reference, so pushing into it updates the
// record (a HashMap has no pushBack of its own).
private _history = _record getOrDefault ["history", []];

_history pushBack createHashMapFromArray [
    ["state", _newState],
    ["byUid", _uid],
    ["byName", name _sender],
    ["at", _at]
];

_record set ["state", _newState];

[_record] call FUNC(serverPushRequest);

// A transition to done/cancelled may have pushed the closed history over
// its cap; terminals are final, so this is the only place that can.
[] call FUNC(serverPruneRequests);

createHashMapFromArray [["ok", true], ["pending", true]]
