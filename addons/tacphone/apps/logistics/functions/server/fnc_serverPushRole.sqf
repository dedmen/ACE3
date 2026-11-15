#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Pushes a Logistics.Role.Changed push for one uid. Ungated broadcast (see
 * below); delivery goes through fnc_serverPushAll (one target event per
 * player).
 *
 * Arguments:
 * 0: Player UID <STRING>
 * 1: Role <STRING> ("player", "worker" or "left")
 * 2: Player name <STRING>
 *
 * The `name` field is RESERVED: the current web UI reads only `uid` and
 * `role`; the name is computed and sent so a future consumer (e.g. a worker
 * list) can display it without a protocol change.
 *
 * Return Value:
 * None
 *
 * Example:
 * ["76561198000000000", "worker", "Alpha 1-1"] call ace_tacphone_Logistics_fnc_serverPushRole
 *
 * Public: No
 */

params ["_uid", "_role", ["_name", ""]];

// Ungated on purpose: role changes are rare and the payload tiny, so the
// push is always a broadcast (the messaging precedent). An interest
// early-out would silently drop the push on a dedicated server, because
// client interests are registered on the machines that host the pages,
// never on the server.

private _push = createHashMapFromArray [
    ["a", "ACE_TacPhone_Logistics"],
    ["c", "Logistics.Role.Changed"],
    ["uid", _uid],
    ["role", _role],
    ["name", _name]
];

[_push] call FUNC(serverPushAll);
