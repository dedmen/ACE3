#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Updates the current leader metadata of an invited group. The whole-group flag
 * itself lives on the room's group record, so a leader change needs no flag
 * migration.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 * 1: Group id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record, "WEST:Alpha 1-1"] call ace_tacphone_Messaging_fnc_serverRefreshGroupFlag
 *
 * Public: No
 */

params ["_record", "_groupId"];

private _group = grpNull;

{
    if (([_x] call FUNC(getGroupId)) == _groupId) exitWith {
        _group = _x;
    };
} forEach allGroups;

if (isNull _group) exitWith {};

private _groups = _record getOrDefault ["groups", createHashMap];
private _tracked = _groups getOrDefault [_groupId, createHashMap];
if (count _tracked > 0) then {
    _tracked set ["leaderUid", getPlayerUID (leader _group)];
};
