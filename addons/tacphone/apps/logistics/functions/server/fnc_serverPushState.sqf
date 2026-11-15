#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Pushes the full Logistics.State snapshot (every request record plus the
 * role map). Ungated by interest (see below); the web side replaces its whole
 * request map with the snapshot, so the order of the list does not matter.
 * Delivery goes through fnc_serverPushAll (one target event per player).
 * Targeted at the requesting player by default; callers may broadcast.
 *
 * Arguments:
 * 0: Targets <ARRAY OF PLAYERS> (default: allPlayers; the GetLogisticsState
 *    path passes the requesting player)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_Logistics_fnc_serverPushState
 *
 * Public: No
 */

params [["_targets", allPlayers]];

// Ungated by interest on purpose: the queue is event-driven and the snapshot
// is requested by a mounted page, so it must always be delivered. An interest
// early-out would drop the snapshot on a dedicated server, where client
// interests never reach the server machine. The target is up to the caller:
// GetLogisticsState passes the requesting player, debug reset broadcasts.

private _requests = [];

{
    private _info = [_x] call FUNC(assembleRequestInfo);
    _requests pushBack _info;
} forEach (values GVAR(serverRequests));

private _push = createHashMapFromArray [
    ["a", "ACE_TacPhone_Logistics"],
    ["c", "Logistics.State"],
    ["requests", _requests],
    ["roles", GVAR(serverRoles)]
];

[_push, _targets] call FUNC(serverPushAll);
