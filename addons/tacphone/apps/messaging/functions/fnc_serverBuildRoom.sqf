#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Creates a room record. The participants map stores one entry per participant
 * (info plus creator flag). The messages array and the room record are shared
 * by reference between every participant's map (see FUNC(serverStoreRoom)).
 *
 * Arguments:
 * 0: Room id <STRING>
 * 1: Room kind <STRING> ("direct" or "group")
 * 2: Room name <STRING>
 * 3: Participant UIDs <ARRAY of STRING>
 * 4: Creator UID <STRING>
 *
 * Return Value:
 * Room record <HASHMAP>
 *
 * Example:
 * ["grp:1_2", "group", "Squad", ["76561198000000000"], "76561198000000000"] call ace_tacphone_Messaging_fnc_serverBuildRoom
 *
 * Public: No
 */

params ["_roomId", "_kind", "_name", "_uids", "_createdBy"];

private _participants = createHashMap;

{
    private _info = [_x] call FUNC(assembleParticipant);
    _info set ["creator", _x == _createdBy];
    _participants set [_x, _info];
} forEach _uids;

createHashMapFromArray [
    ["id", _roomId],
    ["kind", _kind],
    ["name", _name],
    ["participants", _participants],
    ["groups", createHashMap],
    ["messages", []],
    ["createdAt", time],
    ["createdBy", _createdBy],
    ["inviteKey", format ["%1-%2", round (random 999999), round (random 999999)]]
]
