#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the wire representation of a room's current participants.
 *
 * Participants that are no longer known (disconnected and no longer
 * in the game) fall back to the record stored at room creation time,
 * refreshed with their current presence. The creator flag from the stored
 * record and the effective whole-group flag are exposed on the wire
 * participant.
 *
 * Assembly goes through FUNC(serverCachedParticipant): within one open
 * cache scope each UID is resolved once, and callers still get a fresh
 * record to enrich.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 *
 * Return Value:
 * Participants <ARRAY of HASHMAP>
 *
 * Example:
 * [_record] call ace_tacphone_Messaging_fnc_serverRoomParticipants
 *
 * Public: No
 */

params ["_record"];

private _storedParticipants = _record get "participants";
private _participants = [];

{
    private _uid = _x;
    private _stored = _storedParticipants getOrDefault [_uid, createHashMap];
    private _info = [_uid] call FUNC(serverCachedParticipant);

    if ((_info getOrDefault ["name", ""]) == "" && {count _stored > 0}) then {
        // Copy: the stored record is the room's authoritative participant
        // entry, and the enrichment below must not leak into it
        // (groupControlled is not part of the wire participant).
        _info = + _stored;
        _info deleteAt "groupControlled";
        _info set ["presence", [_uid] call FUNC(getPresence)];
    };

    if (_stored getOrDefault ["creator", false]) then {
        _info set ["creator", true];
    };

    // The whole-group flag lives on the room's group record, not on a leader;
    // expose the effective flag on every current member of that group.
    private _trackedGroups = _record getOrDefault ["groups", createHashMap];

    if ((_info getOrDefault ["groupId", ""]) in _trackedGroups) then {
        _info set ["groupInvited", true];
    };

    _participants pushBack _info;
} forEach (keys _storedParticipants);

_participants
