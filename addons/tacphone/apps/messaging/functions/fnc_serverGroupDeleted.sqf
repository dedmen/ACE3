#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Handles an in-game group being deleted. Every member of that group is removed
 * from every room that invited it. Rooms left with no participants are deleted
 * entirely, because nobody is left to invite anyone again.
 *
 * Arguments:
 * 0: Group id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["WEST:Alpha 1-1"] call ace_tacphone_Messaging_fnc_serverGroupDeleted
 *
 * Public: No
 */

params ["_groupId"];

if (_groupId == "") exitWith {};

private _roomIds = keys (GVAR(groupRooms) getOrDefault [_groupId, createHashMap]);

{
    private _record = GVAR(serverRooms) getOrDefault [_x, createHashMap];
    if (count _record == 0) then { continue; };

    private _participants = _record get "participants";
    private _removed = [];

    {
        private _uid = _x;

        private _memberInfo = _participants getOrDefault [_uid, createHashMap];

        if ((_memberInfo getOrDefault ["groupId", ""]) == _groupId) then {
            _participants deleteAt _uid;
            private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefault [_uid, createHashMap];
            _playerRooms deleteAt (_record get "id");
            _removed pushBack _uid;
        };
    } forEach (keys _participants);

    if (count _participants == 0) then {
        [_record, _removed] call FUNC(serverDeleteRoom);
    } else {
        [_record, "The group was deleted in-game; its members left the chat."] call FUNC(serverGroupSystemMessage);
        [_record, _removed] call FUNC(serverBroadcastRoom);
        [_record, _groupId] call FUNC(serverUntrackGroup);
    };
} forEach _roomIds;

// The group object is gone; drop the object-id lookup even if untrack could not
// resolve it any more.
{
    if (_y == _groupId) exitWith {
        GVAR(groupObjectIds) deleteAt _x;
    };
} forEach GVAR(groupObjectIds);
