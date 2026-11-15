#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Pushes one Logistics.Request.Upsert push for a request. Ungated
 * broadcast (see below); delivery goes through fnc_serverPushAll (one
 * target event per player).
 *
 * Arguments:
 * 0: Request record <HASHMAP>
 * 1: Client token <STRING> (optional; H-4. The token of the create that
 *    produced the record, echoed for the web dialog's correlation. Never
 *    stored on the record; "" for every non-create push.)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record] call ace_tacphone_Logistics_fnc_serverPushRequest
 *
 * Public: No
 */

params ["_record", ["_clientToken", ""]];

// Ungated on purpose: the queue is event-driven and the payload small, so
// the push is always a broadcast (the messaging precedent). An interest
// early-out would silently drop every push on a dedicated server, because
// client interests are registered on the machines that host the pages,
// never on the server.

private _push = createHashMapFromArray [
    ["a", "ACE_TacPhone_Logistics"],
    ["c", "Logistics.Request.Upsert"],
    ["request", [_record] call FUNC(assembleRequestInfo)]
];

if (_clientToken != "") then {
    _push set ["clientToken", _clientToken];
};

[_push] call FUNC(serverPushAll);
