#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Resolves a group id (see FUNC(getGroupId)) to the PlayerUIDs of its current
 * human members. Membership is always resolved on the server, the client is
 * never trusted with it.
 *
 * Arguments:
 * 0: Group id <STRING>
 *
 * Return Value:
 * Member UIDs <ARRAY of STRING>
 *
 * Example:
 * ["WEST:Alpha 1-1"] call ace_tacphone_Messaging_fnc_getGroupMemberUids
 *
 * Public: No
 */

params ["_groupId"];

private _uids = [];

{
    if (([_x] call FUNC(getGroupId)) == _groupId) exitWith {
        {
            if (isPlayer _x) then {
                _uids pushBack (getPlayerUID _x);
            };
        } forEach (units _x);
    };
} forEach allGroups;

#ifdef __A3_DEBUG__
private _fakeGroup = GVAR(debugFakeGroups) getOrDefault [_groupId, createHashMap];

if (count _fakeGroup > 0) then {
    {
        if (!(_x in _uids)) then {
            _uids pushBack _x;
        };
    } forEach (_fakeGroup getOrDefault ["memberUids", []]);
};
#endif

_uids
