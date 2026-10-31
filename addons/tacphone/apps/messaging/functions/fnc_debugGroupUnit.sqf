#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Debug-only group event test helper. Spawns an AI unit into a temporary group,
 * marks it with a synthetic UID, then joins it to the sender's group (which
 * triggers UnitJoined). Removing it deletes the unit, triggering UnitLeft.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "action": "spawn"|"remove", "uid": "" })
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["action", "spawn"]], player] call ace_tacphone_Messaging_fnc_debugGroupUnit
 *
 * Public: No
 */

params ["_request", "_sender"];

if (isNull _sender) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _action = _request getOrDefault ["action", "spawn"];

if (_action == "spawn") then {
    private _uid = format ["debug_ai_%1", round (random 999999999)];
    private _className = switch (side _sender) do {
        case west: { "B_Soldier_F" };
        case east: { "O_Soldier_F" };
        case resistance: { "I_Soldier_F" };
        default { "C_man_1" };
    };

    private _tempGroup = createGroup (side _sender);
    private _unit = _tempGroup createUnit [_className, getPosATL _sender, [], 0, "NONE"];

    if (isNull _unit) exitWith {
        deleteGroup _tempGroup;
        createHashMapFromArray [["ok", false], ["error", "Could not create a test AI unit"]]
    };

    _unit setVariable [QGVAR(debugUid), _uid, true];
    _unit setVariable [QGVAR(debugGroupUnit), true, true];

    private _group = group _sender;
    if (isNull _group) then {
        _group = createGroup (side _sender);
    };

    GVAR(debugGroupUnits) set [_uid, _unit];
    GVAR(debugFakePlayers) set [_uid, createHashMapFromArray [
        ["uid", _uid],
        ["name", format ["Debug AI %1", _uid select [9, 6]]],
        ["side", str (side _sender)],
        ["groupId", [_group] call FUNC(getGroupId)],
        ["groupName", groupId _group],
        ["presence", MESSAGING_PRESENCE_OFFLINE]
    ]];

    [_unit] joinSilent _group;
    [_sender] call FUNC(serverPushPlayerList);

    createHashMapFromArray [
        ["ok", true],
        ["uid", _uid],
        ["name", name _unit]
    ]
} else {
    if (_action != "remove") exitWith {
        createHashMapFromArray [["ok", false], ["error", "Unknown group unit action"]]
    };

    private _uid = _request getOrDefault ["uid", ""];
    private _unit = GVAR(debugGroupUnits) getOrDefault [_uid, objNull];

    if (isNull _unit) exitWith {
        createHashMapFromArray [["ok", false], ["error", "Debug group unit not found"]]
    };

    deleteVehicle _unit;
    GVAR(debugGroupUnits) deleteAt _uid;
    GVAR(debugFakePlayers) deleteAt _uid;
    [_sender] call FUNC(serverPushPlayerList);

    createHashMapFromArray [["ok", true], ["uid", _uid]]
};
#endif
