#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Resolves the side string of one PlayerUID for the side-equality checks
 * (group joins, public room listing, can-chat).
 *
 * Known players (real units and debug fake players) resolve through
 * FUNC(assembleParticipant), which reads the side from the unit's group
 * because dead and captive units report CIVILIAN. UIDs that resolve to
 * nobody fall back to the side stored on their room participant record;
 * "" means the player cannot be placed on any side, which callers treat
 * as "not allowed".
 *
 * Arguments:
 * 0: Player UID <STRING>
 * 1: Stored participant record <HASHMAP> (optional; may be empty)
 *
 * Return Value:
 * Side <STRING> ("" when the player cannot be resolved to a side)
 *
 * Example:
 * ["76561198000000000", createHashMap] call ace_tacphone_Messaging_fnc_participantSide
 *
 * Public: No
 */

params ["_uid", ["_stored", createHashMap]];

private _info = [_uid] call FUNC(assembleParticipant);

if ((_info getOrDefault ["name", ""]) != "") exitWith {
    _info getOrDefault ["side", ""]
};

_stored getOrDefault ["side", ""]
