#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the participant record of one PlayerUID for the web contract.
 *
 * Real players are refreshed from their unit (name, group, side). Debug fake
 * players come from GVAR(debugFakePlayers). Unknown UIDs return an empty name,
 * which callers treat as "not a known player".
 *
 * Group colours are not implemented yet:
 * TODO: use the future group member colour system for groupColor.
 *
 * Arguments:
 * 0: Player UID <STRING>
 * 1: Presence <STRING> (optional; defaults to the server presence of the player)
 *
 * Return Value:
 * Participant <HASHMAP> ({uid, name, presence, side, groupId, groupName, groupColor?})
 *
 * Example:
 * ["76561198000000000"] call ace_tacphone_Messaging_fnc_assembleParticipant
 *
 * Public: No
 */

params ["_uid", ["_presence", ""]];

if (_presence == "") then {
    _presence = [_uid] call FUNC(getPresence);
};

private _info = createHashMapFromArray [
    ["uid", _uid],
    ["name", ""],
    ["presence", _presence]
];

private _player = [_uid] call FUNC(getPlayerByUid);

if (!isNull _player) exitWith {
    private _group = group _player;
    private _groupId = groupId _group;

    _info set ["name", name _player];
    _info set ["side", str (side _player)];

    if (_groupId != "") then {
        // GroupListEntry.id is side-prefixed; participants must use the same id
        // so group tracking and the UI grouping key always match.
        _info set ["groupId", [_group] call FUNC(getGroupId)];
        _info set ["groupName", _groupId];
    };

    _info
};

#ifdef __A3_DEBUG__
private _fake = GVAR(debugFakePlayers) getOrDefault [_uid, createHashMap];

if (count _fake > 0) exitWith {
    private _color = _fake getOrDefault ["groupColor", ""];

    _info set ["name", _fake getOrDefault ["name", _uid]];
    _info set ["side", _fake getOrDefault ["side", ""]];
    _info set ["groupId", _fake getOrDefault ["groupId", ""]];
    _info set ["groupName", _fake getOrDefault ["groupName", ""]];

    if (_color != "") then {
        _info set ["groupColor", _color];
    };

    _info
};
#endif

_info
