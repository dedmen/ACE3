#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Collects the unique side strings of a room's current participants.
 *
 * Used to find every side whose public room list changes when a room's
 * membership changes. Participants that cannot be resolved to a side are
 * skipped.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 *
 * Return Value:
 * Sides <ARRAY of STRING> (unique)
 *
 * Example:
 * [_record] call ace_tacphone_Messaging_fnc_serverParticipantSides
 *
 * Public: No
 */

params ["_record"];

private _sides = [];
private _participants = _record get "participants";

{
    private _stored = _participants getOrDefault [_x, createHashMap];
    private _side = [_x, _stored] call FUNC(participantSide);

    if (_side != "") then {
        _sides pushBackUnique _side;
    };
} forEach (keys _participants);

_sides
