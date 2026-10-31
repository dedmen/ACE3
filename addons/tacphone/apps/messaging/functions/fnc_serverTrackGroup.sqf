#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Tracks an in-game group as a room participant source. The room still stores
 * only PlayerUIDs; the group's current leader gets the `groupInvited` flag and
 * the server subscribes to the group's UnitJoined / UnitLeft / Deleted events.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 * 1: Group id <STRING> (see FUNC(getGroupId))
 * 2: Sender <OBJECT> (used for the side restriction)
 *
 * Return Value:
 * Number of human players added <NUMBER>
 *
 * Example:
 * [_record, "WEST:Alpha 1-1", player] call ace_tacphone_Messaging_fnc_serverTrackGroup
 *
 * Public: No
 */

params ["_record", "_groupId", "_sender"];

if (isNull _sender) exitWith { 0 };
if ((_record getOrDefault ["kind", ""]) != "group") exitWith { 0 };

private _group = grpNull;

{
    if (([_x] call FUNC(getGroupId)) == _groupId) exitWith {
        _group = _x;
    };
} forEach allGroups;

private _groups = _record getOrDefault ["groups", createHashMap];
_record set ["groups", _groups];

if (isNull _group) exitWith {
    private _added = 0;

    #ifdef __A3_DEBUG__
    // Fake debug groups have no engine group object, so they cannot report
    // membership changes; add their current members once.
    private _fakeGroup = GVAR(debugFakeGroups) getOrDefault [_groupId, createHashMap];

    if (count _fakeGroup > 0) then {
        {
            if (([_x] call FUNC(assembleParticipant)) getOrDefault ["name", ""] != "") then {
                if ([_record, _x] call FUNC(serverAddParticipantToRoom)) then {
                    _added = _added + 1;
                };
            };
        } forEach (_fakeGroup getOrDefault ["memberUids", []]);

        _groups set [_groupId, createHashMapFromArray [
            ["leaderUid", _fakeGroup getOrDefault ["memberUids", []] param [0, ""]],
            ["handlerIds", []]
        ]];
    };
    #endif

    _added
};

private _roomId = _record get "id";
private _roomMap = GVAR(groupRooms) getOrDefaultCall [_groupId, {createHashMap}, true];
_roomMap set [_roomId, true];

private _tracked = _groups getOrDefault [_groupId, createHashMap];

if (count _tracked == 0) then {
    private _handlerIds = [];

    _group setVariable [QGVAR(groupId), _groupId];
    GVAR(groupObjectIds) set [str _group, _groupId];

    _handlerIds pushBack ["UnitJoined", _group addEventHandler ["UnitJoined", {
        params ["_group", "_unit"];
        [_group getVariable [QGVAR(groupId), ""], _unit, "joined"] call FUNC(serverGroupChanged);
    }]];

    _handlerIds pushBack ["UnitLeft", _group addEventHandler ["UnitLeft", {
        params ["_group", "_unit"];
        [_group getVariable [QGVAR(groupId), ""], _unit, "left"] call FUNC(serverGroupChanged);
    }]];

    _handlerIds pushBack ["Deleted", _group addEventHandler ["Deleted", {
        params ["_group"];
        private _groupId = GVAR(groupObjectIds) getOrDefault [str _group, ""];

        if (_groupId == "") then {
            _groupId = _group getVariable [QGVAR(groupId), ""];
        };

        [_groupId] call FUNC(serverGroupDeleted);
    }]];

    _tracked = createHashMapFromArray [
        ["leaderUid", getPlayerUID (leader _group)],
        ["handlerIds", _handlerIds]
    ];
    _groups set [_groupId, _tracked];
};

private _added = 0;
private _senderSide = str (side _sender);
private _participants = _record get "participants";
private _groupName = groupId _group;
private _senderGroup = group _sender;

// The player who brings their own group into the room is group-controlled even
// if the engine's units list is temporarily missing them.
if (!isNull _senderGroup && {([_senderGroup] call FUNC(getGroupId)) == _groupId}) then {
    private _senderUid = getPlayerUID _sender;

    if (_senderUid in _participants) then {
        private _senderInfo = _participants get _senderUid;
        _senderInfo set ["groupId", _groupId];
        _senderInfo set ["groupName", _groupName];
        _senderInfo set ["groupControlled", true];
    };
};

{
    private _memberUid = getPlayerUID _x;
    private _debugUnit = false;

    #ifdef __A3_DEBUG__
    private _debugUid = _x getVariable [QGVAR(debugUid), ""];

    if (_debugUid != "") then {
        _memberUid = _debugUid;
        _debugUnit = true;
    };
    #endif

    // Real players are always eligible. AI is ignored unless the debug tooling
    // explicitly marks the unit for group-event testing.
    if ((isPlayer _x || _debugUnit) && {_memberUid != ""} && {str (side _x) == _senderSide}) then {
        if ([_record, _memberUid] call FUNC(serverAddParticipantToRoom)) then {
            _added = _added + 1;
        };

        if (_memberUid in _participants) then {
            private _info = _participants get _memberUid;
            _info set ["groupId", _groupId];
            _info set ["groupName", _groupName];
            _info set ["groupControlled", true];
        };
    };
} forEach (units _group);

[_record, _groupId] call FUNC(serverRefreshGroupFlag);

_added
