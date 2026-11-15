#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Rebuilds room records from serialized state and re-establishes the shared
 * array/record references between the player maps. Persistence is disabled;
 * this only runs when called explicitly (for example by the debug commands).
 *
 * The import replaces the running rooms wholesale: the state is validated
 * first (a malformed entry must not wipe the live rooms), the groups tracked
 * by the old rooms are untracked before the maps are dropped, and the
 * exported groups are re-tracked so in-game group changes keep flowing into
 * the restored rooms. A group that no longer exists (or has no units) cannot
 * be re-tracked and its members' group fields are cleared — a
 * groupControlled flag without a tracked group would lock a player into the
 * room.
 *
 * Arguments:
 * 0: Serialized state <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[true] call ace_tacphone_Messaging_fnc_serverExportState] call ace_tacphone_Messaging_fnc_serverImportState
 *
 * Public: No
 */

params ["_state"];

if (!(_state isEqualType createHashMap)) exitWith {};
if (count _state == 0) exitWith {};

private _rooms = _state getOrDefault ["rooms", []];

// Validate before wiping, so a malformed entry aborts with the live rooms
// intact instead of destroying them without a replacement.
private _seenRoomIds = createHashMap;

{
    private _data = _x;

    if (!(_data isEqualType createHashMap)) exitWith {};

    private _roomId = _data getOrDefault ["id", ""];

    if (!(_roomId isEqualType "") || {_roomId == ""}) exitWith {};

    // A duplicate id would overwrite the first record while its
    // serverRoomsByPlayer entries keep pointing at the orphaned record,
    // desyncing the two maps.
    if (_seenRoomIds getOrDefault [_roomId, false]) exitWith {};
    _seenRoomIds set [_roomId, true];

    // A malformed participant pair would corrupt the rebuilt record: a
    // missing info hashmap breaks every later get/set on the entry.
    {
        private _entry = _x;
        private _uid = _entry param [0, ""];
        private _info = _entry param [1, nil];

        if ((count _entry != 2) || {!(_uid isEqualType "") || {_uid == ""}} || {!(_info isEqualType createHashMap)}) exitWith {};
    } forEach (_data getOrDefault ["participants", []]);
} forEach _rooms;

// Untrack the groups of the rooms being replaced: the engine event handlers
// and the tracking maps must not outlive the records that reference them.
{
    private _record = _x;

    {
        // keys() iterates the group id keys: the id is _x.
        [_record, _x] call FUNC(serverUntrackGroup);
    } forEach (keys (_record getOrDefault ["groups", createHashMap]));
} forEach (values GVAR(serverRooms));

GVAR(serverRooms) = createHashMap;
GVAR(serverRoomsByPlayer) = createHashMap;
GVAR(serverMessageCounter) = _state getOrDefault ["messageCounter", 0];
GVAR(serverRoomCounter) = _state getOrDefault ["roomCounter", 0];

private _groupTracks = [];

{
    private _data = _x;
    private _participantMap = createHashMap;

    // The exported group fields are kept for now; the re-tracking pass below
    // re-resolves every group and clears the fields of members the group no
    // longer contains.
    {
        _participantMap set [_x select 0, _x select 1];
    } forEach (_data getOrDefault ["participants", []]);

    private _record = createHashMapFromArray [
        ["id", _data get "id"],
        ["kind", _data getOrDefault ["kind", "group"]],
        ["name", _data getOrDefault ["name", ""]],
        ["participants", _participantMap],
        ["groups", createHashMap],
        ["messages", _data getOrDefault ["messages", []]],
        ["createdAt", _data getOrDefault ["createdAt", 0]],
        ["createdBy", _data getOrDefault ["createdBy", ""]],
        ["inviteKey", _data getOrDefault ["inviteKey", ""]]
    ];

    GVAR(serverRooms) set [_record get "id", _record];

    {
        private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefaultCall [_x, {createHashMap}, true];
        _playerRooms set [_record get "id", _record];
    } forEach (keys _participantMap);

    _groupTracks pushBack [_record, _data getOrDefault ["groups", []]];
} forEach _rooms;

// Re-track the exported groups so in-game group changes keep flowing into
// the restored rooms. The group's leader (or any unit) serves as the
// tracking sender: its side is the group's side, so the membership check
// re-adds the current members.
{
    private _record = _x select 0;
    private _participants = _record get "participants";

    {
        private _groupId = _x;
        private _group = grpNull;

        {
            if (([_x] call FUNC(getGroupId)) == _groupId) exitWith {
                _group = _x;
            };
        } forEach allGroups;

        private _sender = leader _group;

        if (isNull _sender) then {
            _sender = (units _group) param [0, objNull];
        };

        if (isNull _sender) then {
            // The group no longer exists (or has no unit left): tracking
            // cannot be restored, so the stale group fields go.
            {
                private _info = _participants get _x;

                if ((_info getOrDefault ["groupId", ""]) == _groupId) then {
                    _info deleteAt "groupId";
                    _info deleteAt "groupName";
                    _info deleteAt "groupControlled";
                };
            } forEach (keys _participants);
        } else {
            private _groupUids = [];
            { _groupUids pushBack (getPlayerUID _x); } forEach (units _group);

            // Clear the stale fields of members the group no longer contains
            // first; FUNC(serverTrackGroup) then re-sets them on the current
            // members and re-adds any that joined in-game after the export.
            {
                private _info = _participants get _x;

                if (((_info getOrDefault ["groupId", ""]) == _groupId) && {!(_x in _groupUids)}) then {
                    _info deleteAt "groupId";
                    _info deleteAt "groupName";
                    _info deleteAt "groupControlled";
                };
            } forEach (keys _participants);

            [_record, _groupId, _sender] call FUNC(serverTrackGroup);
        };
    } forEach (_x select 1);
} forEach _groupTracks;
