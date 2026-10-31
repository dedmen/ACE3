#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Creates or deletes a synthetic AI-only group for group-event and inter-group
 * chat tests. The AI units get synthetic PlayerUIDs and a debug fake-player
 * record, and are ignored by release code.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "action": "create"|"delete", "count": 2, "name": "", "groupId": "" })
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["action", "create"]], player] call ace_tacphone_Messaging_fnc_debugAIGroup
 *
 * Public: No
 */

params ["_request", "_sender"];

if (isNull _sender) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _action = _request getOrDefault ["action", "create"];

if (_action == "create") then {
    private _count = (_request getOrDefault ["count", 2]) max 1 min 8;
    private _group = createGroup (side _sender);
    private _displayName = _request getOrDefault ["name", format ["T7 AI %1", round (random 999999)]];
    _group setGroupId [_displayName];

    private _groupId = [_group] call FUNC(getGroupId);
    private _memberUids = [];

    for "_index" from 1 to _count do {
        private _className = switch (side _sender) do {
            case west: { "B_Soldier_F" };
            case east: { "O_Soldier_F" };
            case resistance: { "I_Soldier_F" };
            default { "C_man_1" };
        };

        private _unit = _group createUnit [_className, getPosATL _sender, [], 0, "NONE"];
        private _uid = format ["debug_ai_%1_%2", round (random 999999), _index];

        _unit setVariable [QGVAR(debugUid), _uid, true];
        _unit setVariable [QGVAR(debugGroupUnit), true, true];

        private _name = format ["%1 %2", _displayName, _index];

        GVAR(debugGroupUnits) set [_uid, _unit];
        GVAR(debugFakePlayers) set [_uid, createHashMapFromArray [
            ["uid", _uid],
            ["name", _name],
            ["side", str (side _sender)],
            ["groupId", _groupId],
            ["groupName", _displayName],
            ["presence", MESSAGING_PRESENCE_OFFLINE]
        ]];

        _memberUids pushBack _uid;
    };

    GVAR(debugAIGroups) set [_groupId, _group];
    GVAR(debugFakeGroups) set [_groupId, createHashMapFromArray [
        ["id", _groupId],
        ["name", _displayName],
        ["side", str (side _sender)],
        ["color", "#ffaa00"],
        ["memberUids", _memberUids]
    ]];

    [_sender] call FUNC(serverPushPlayerList);

    createHashMapFromArray [
        ["ok", true],
        ["groupId", _groupId],
        ["memberUids", _memberUids]
    ]
} else {
    if (_action != "delete") exitWith {
        createHashMapFromArray [["ok", false], ["error", "Unknown AI group action"]]
    };

    private _groupId = _request getOrDefault ["groupId", ""];
    private _group = GVAR(debugAIGroups) getOrDefault [_groupId, grpNull];

    if (isNull _group) exitWith {
        createHashMapFromArray [["ok", false], ["error", "AI group not found"]]
    };

    // deleteGroup requires an empty group. Delete every member first (this
    // fires UnitLeft for tracked groups); the empty group then fires Deleted.
    _group deleteGroupWhenEmpty true;

    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach (units _group);

    if (!isNull _group) then {
        deleteGroup _group;
    };

    GVAR(debugAIGroups) deleteAt _groupId;
    GVAR(debugFakeGroups) deleteAt _groupId;

    {
        if ((_y getOrDefault ["groupId", ""]) == _groupId) then {
            GVAR(debugFakePlayers) deleteAt _x;
            GVAR(debugGroupUnits) deleteAt _x;
        };
    } forEach +GVAR(debugFakePlayers);

    [_sender] call FUNC(serverPushPlayerList);

    createHashMapFromArray [["ok", true], ["groupId", _groupId]]
};
#endif
