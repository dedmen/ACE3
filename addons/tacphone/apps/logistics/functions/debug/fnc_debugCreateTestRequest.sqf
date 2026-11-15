#include "..\..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Debug-only deterministic test request: a position-kind request with the
 * fixed description "Debug test request" at the sender's rounded position,
 * optionally shifted by an offset. It is created through the normal
 * CreateRequest path, so validation, the Messenger room and the upsert push
 * all run for real.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "Debug.CreateTestRequest", "offset": [dx, dy] (optional, default [0, 0]), "created": epoch string (optional, forwarded) })
 * 1: Sender <OBJECT> (player the test request is attributed to)
 *
 * Return Value:
 * Result <HASHMAP> (the serverCreateRequest result: {ok: true, pending: true} on success, {ok: false, error} on rejection)
 *
 * Example:
 * [createHashMapFromArray [["c", "Debug.CreateTestRequest"], ["offset", [50, -30]]], player] call ace_tacphone_Logistics_fnc_debugCreateTestRequest
 *
 * Public: No
 */

params ["_request", "_sender"];

if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
    createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]]
};

REQUIRE_SENDER(_sender);

// The caller's client stamp, forwarded as created; a direct SQF call has no
// client clock and the record keeps an empty date.
private _created = _request getOrDefault ["created", ""];
if !(_created isEqualType "") then {
    _created = "";
};

// Deterministic position: the sender's rounded position, optionally shifted
// so a live test can place a request a known distance away.
private _position = getPos _sender;
private _offset = _request getOrDefault ["offset", [0, 0]];
private _shifted = [
    round (_position select 0) + (_offset param [0, 0]),
    round (_position select 1) + (_offset param [1, 0])
];

private _createRequest = createHashMapFromArray [
    ["c", "CreateRequest"],
    ["description", "Debug test request"],
    ["created", _created],
    ["location", createHashMapFromArray [
        ["kind", "position"],
        ["marker", ""],
        ["position", _shifted]
    ]]
];

[_createRequest, _sender] call FUNC(serverCreateRequest)
#endif
