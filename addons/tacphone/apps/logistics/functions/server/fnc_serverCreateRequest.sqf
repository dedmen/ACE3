#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Validates a CreateRequest (description, location type/shape, created),
 * builds the request record, creates the request's Messenger room, stores
 * the record in GVAR(serverRequests) and broadcasts the new request through
 * the Logistics.Request.Upsert push, echoing the request's clientToken so
 * the web dialog can correlate its own send.
 *
 * The room boundary (FUNC(serverRoomAccess)) falls back to "" when the
 * Messaging app is absent, so a request is still created and pushed.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "CreateRequest", "description": "", "location": { kind, marker, position }, "created": "", "clientToken": "" })
 * 1: Sender <OBJECT> (player creating the request)
 *
 * Return Value:
 * Result <HASHMAP> ({ok: true, pending: true} on success, {ok: false, error} on rejection)
 *
 * Example:
 * [_request, player] call ace_tacphone_Logistics_fnc_serverCreateRequest
 *
 * Public: No
 */

params ["_request", "_sender"];

if (isNull _sender) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _description = _request getOrDefault ["description", ""];

// JSON strings arrive as SQF strings; `str` would add quotes to them.
if !(_description isEqualType "") then {
    _description = "";
};

_description = trim _description;

if (_description == "") exitWith {
    createHashMapFromArray [["ok", false], ["error", "empty description"]]
};

if (count _description > 500) exitWith {
    createHashMapFromArray [["ok", false], ["error", "description too long"]]
};

// H-5: the web validates the payload, but the queue is server-authoritative
// and every stored record counts toward the cap, so a malformed location
// must be rejected, not stored as an invisible request. All guards are flat
// top-level statements (AGENTS/sqf.md: a nested exitWith exits only the
// branch block, not the function).
private _location = _request getOrDefault ["location", ""];
if !(_location isEqualType createHashMap) exitWith {
    createHashMapFromArray [["ok", false], ["error", "invalid location"]]
};

private _kind = _location getOrDefault ["kind", ""];
if !(_kind isEqualType "") then {
    _kind = "";
};
if (_kind != "position" && {_kind != "marker"}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "invalid location kind"]]
};

private _position = _location getOrDefault ["position", []];
if (!(_position isEqualType []) || {count _position != 2}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "invalid position"]]
};

private _x = _position select 0;
private _y = _position select 1;
// `finite` is the SQF NaN/infinity guard (there is no isNaN); the type guard
// above keeps it fed numbers.
if (!(_x isEqualType 0) || {!(_y isEqualType 0)} || {!(finite _x)} || {!(finite _y)}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "invalid position"]]
};

private _marker = _location getOrDefault ["marker", ""];
if !(_marker isEqualType "") then {
    _marker = "";
};
if (_kind == "marker" && {_marker == ""}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "missing marker"]]
};
if (count _marker > 128) exitWith {
    createHashMapFromArray [["ok", false], ["error", "marker too long"]]
};

// H-4: echoed in the create's upsert so the dialog can correlate its own
// send; validated here, never stored on the record.
private _clientToken = _request getOrDefault ["clientToken", ""];
if (!(_clientToken isEqualType "") || {count _clientToken > 64}) then {
    _clientToken = "";
};

// Open = state not done/cancelled. The cap is a safety limit against a
// runaway client, not a gameplay one. The loop copies `_x` immediately:
// the coordinate above reuses the same name.
private _openCount = 0;

{
    private _entry = _x;
    private _state = _entry getOrDefault ["state", ""];

    if (_state != LOGISTICS_STATE_DONE && {_state != LOGISTICS_STATE_CANCELLED}) then {
        _openCount = _openCount + 1;
    };
} forEach values GVAR(serverRequests);

if (_openCount >= LOGISTICS_QUEUE_CAP) exitWith {
    createHashMapFromArray [["ok", false], ["error", "queue full"]]
};

// Increment first: the first request after a mission start (counter 0) takes
// id L-1, matching the plan ("L-" + counter, like the Messenger room counter).
private _counter = GVAR(serverRequestCounter) + 1;
GVAR(serverRequestCounter) = _counter;

// M-1: a client-supplied created is kept only when it is a sane UTC epoch
// seconds string (10 digits, 1e9..4e9); a wrong clock or forged value would
// otherwise reorder the queue. Invalid values render as the time placeholder
// on the web. The digit check uses regexMatch, not `str parseNumber _value`:
// `str` renders an epoch in scientific notation ("1.76723e+09"), so the
// round-trip never matched.
private _isEpoch = {
    params ["_value"];
    if !(_value isEqualType "") exitWith { false };
    private _n = parseNumber _value;
    (_n >= 1000000000) && {_n <= 4000000000} && {_value regexMatch '[0-9]{10}'}
};
private _created = _request getOrDefault ["created", ""];
if !([_created] call _isEpoch) then {
    _created = "";
};
private _uid = getPlayerUID _sender;
private _requesterName = name _sender;

private _record = createHashMapFromArray [
    ["id", "L-" + (str _counter)],
    ["description", _description],
    // L-10: _kind is validated above, so it is stored as-is (no coercion).
    ["location", createHashMapFromArray [
        ["kind", _kind],
        ["marker", if (_kind == "marker") then { _marker } else { "" }],
        ["position", _position]
    ]],
    ["requesterUid", _uid],
    ["requesterName", _requesterName],
    ["created", _created],
    ["state", LOGISTICS_STATE_QUEUED],
    ["history", [
        createHashMapFromArray [
            ["state", LOGISTICS_STATE_QUEUED],
            ["byUid", _uid],
            ["byName", _requesterName],
            ["at", _created]
        ]
    ]],
    ["roomId", ""]
];

GVAR(serverRequests) set [_record get "id", _record];

// The room needs the stored record and must exist before the push so the
// upsert already carries the roomId.
private _roomId = ["create", _record, _sender] call FUNC(serverRoomAccess);

if (_roomId != "") then {
    _record set ["roomId", _roomId];
};

[_record, _clientToken] call FUNC(serverPushRequest);

createHashMapFromArray [["ok", true], ["pending", true]]
