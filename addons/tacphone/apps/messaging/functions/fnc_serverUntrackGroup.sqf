#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Removes one room from a group's tracking map. When no room tracks the group
 * any more, the group event handlers are removed.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 * 1: Group id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record, "WEST:Alpha 1-1"] call ace_tacphone_Messaging_fnc_serverUntrackGroup
 *
 * Public: No
 */

params ["_record", "_groupId"];

private _groups = _record getOrDefault ["groups", createHashMap];
private _tracked = _groups getOrDefault [_groupId, createHashMap];

if (count _tracked == 0) exitWith {};

private _roomId = _record get "id";
private _roomMap = GVAR(groupRooms) getOrDefault [_groupId, createHashMap];
_roomMap deleteAt _roomId;

_groups deleteAt _groupId;

if (count _roomMap > 0) exitWith {};

GVAR(groupRooms) deleteAt _groupId;

private _group = grpNull;

{
    if (([_x] call FUNC(getGroupId)) == _groupId) exitWith {
        _group = _x;
    };
} forEach allGroups;

if (isNull _group) exitWith {};

{
    _group removeEventHandler [_x select 0, _x select 1];
} forEach (_tracked getOrDefault ["handlerIds", []]);

GVAR(groupObjectIds) deleteAt (str _group);
_group setVariable [QGVAR(groupId), nil];
