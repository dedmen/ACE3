#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Creates deterministic fake players, groups, sides and presence for UI tests.
 * Fake players take part in player lists, room creation, messages, forwarding,
 * invites and presence broadcasts like real players, but have no unit.
 *
 * Only compiled into builds made with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "count": 8 })
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["count", 8]], player] call ace_tacphone_Messaging_fnc_debugAddFakePlayers
 *
 * Public: No
 */

params ["_request", "_sender"];

private _count = _request getOrDefault ["count", 8];

private _groupDefs = [
    ["fake_grp_1", "Fake Alpha", "WEST", "#4aa3df"],
    ["fake_grp_2", "Fake Bravo", "WEST", "#7ed321"],
    ["fake_grp_3", "Fake Charlie", "EAST", "#d0021b"]
];

private _names = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel"];
private _presences = [MESSAGING_PRESENCE_AVAILABLE, MESSAGING_PRESENCE_MINIMIZED, MESSAGING_PRESENCE_OFFLINE];

GVAR(debugFakePlayers) = createHashMap;
GVAR(debugFakeGroups) = createHashMap;

{
    GVAR(debugFakeGroups) set [_x select 0, createHashMapFromArray [
        ["id", _x select 0],
        ["name", _x select 1],
        ["side", _x select 2],
        ["color", _x select 3],
        ["memberUids", []]
    ]];
} forEach _groupDefs;

for "_index" from 1 to _count do {
    private _groupDef = _groupDefs select ((_index - 1) mod (count _groupDefs));
    private _uid = format ["fake_%1", _index];
    private _presence = _presences select ((_index - 1) mod 3);

    GVAR(debugFakePlayers) set [_uid, createHashMapFromArray [
        ["uid", _uid],
        ["name", format ["Fake %1 %2", _names select ((_index - 1) mod (count _names)), _index]],
        ["side", _groupDef select 2],
        ["groupId", _groupDef select 0],
        ["groupName", _groupDef select 1],
        ["groupColor", _groupDef select 3],
        ["presence", _presence]
    ]];

    GVAR(serverPlayerPresence) set [_uid, _presence];
};

// Build the member lists after all players exist.
{
    private _group = _x;
    private _members = [];

    {
        if ((_x getOrDefault ["groupId", ""]) == (_group get "id")) then {
            _members pushBack (_x get "uid");
        };
    } forEach (values GVAR(debugFakePlayers));

    _group set ["memberUids", _members];
} forEach (values GVAR(debugFakeGroups));

[_sender] call FUNC(serverPushPlayerList);

createHashMapFromArray [["ok", true], ["count", count GVAR(debugFakePlayers)]]
#endif
