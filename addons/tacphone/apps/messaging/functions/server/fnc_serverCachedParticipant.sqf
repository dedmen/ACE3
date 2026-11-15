#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Cached variant of FUNC(assembleParticipant) for broadcast paths (O3).
 *
 * While a scope is open (FUNC(serverBeginParticipantScope)) the assembled
 * record is cached per UID and a fresh copy is returned, so one broadcast
 * run resolves each unit/group/side once instead of per room participant.
 * Outside a scope the world may move between calls and the participant is
 * assembled live.
 *
 * Arguments:
 * 0: Player UID <STRING>
 *
 * Return Value:
 * Participant <HASHMAP> (fresh record, safe to enrich)
 *
 * Example:
 * ["76561198000000000"] call ace_tacphone_Messaging_fnc_serverCachedParticipant
 *
 * Public: No
 */

params ["_uid"];

if (GVAR(serverParticipantScope) == 0) exitWith {
    [_uid] call FUNC(assembleParticipant)
};

private _cache = GVAR(serverParticipantCache);
private _cached = _cache getOrDefault [_uid, createHashMap];

if (count _cached > 0) exitWith {
    // Copy: callers enrich the returned record (creator, groupInvited,
    // presence) and that must not leak into the cached entry.
    + _cached
};

private _info = [_uid] call FUNC(assembleParticipant);
_cache set [_uid, _info];

_info
