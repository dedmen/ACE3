#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Handles an in-game group UnitJoined / UnitLeft event for every room that
 * invited the group. AI units are ignored; only human players become room
 * participants.
 *
 * Arguments:
 * 0: Group id <STRING>
 * 1: Unit <OBJECT>
 * 2: Event <STRING> ("joined" or "left")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["WEST:Alpha 1-1", _unit, "joined"] call ace_tacphone_Messaging_fnc_serverGroupChanged
 *
 * Public: No
 */

params ["_groupId", "_unit", "_event"];

if (_groupId == "") exitWith {};
if (isNull _unit) exitWith {};

private _uid = if (isPlayer _unit) then { getPlayerUID _unit } else { "" };
private _isDebugUnit = false;

#ifdef __A3_DEBUG__
private _debugUid = _unit getVariable [QGVAR(debugUid), ""];

if (_debugUid != "") then {
    _uid = _debugUid;
    _isDebugUnit = true;
};
#endif

if (_uid == "") exitWith {};
if (!isPlayer _unit && {!_isDebugUnit}) exitWith {};

// Group events run to completion without yielding; open the participant
// cache scope for the whole run (O3/O2).
[] call FUNC(serverBeginParticipantScope);

private _roomIds = keys (GVAR(groupRooms) getOrDefault [_groupId, createHashMap]);

{
    private _record = GVAR(serverRooms) getOrDefault [_x, createHashMap];
    if (count _record == 0) then { continue; };

    // Sides of the current participants before the mutation; a public room's
    // lists must be refreshed for every side involved in the change.
    private _oldSides = [_record] call FUNC(serverParticipantSides);

    private _participants = _record get "participants";

    if (_event == "joined") then {
        if (_uid in _participants) then {
            // Self-merge: the player is already in the room (invited
            // individually, or via another tracked group) and joined one of
            // the room's tracked groups. Refresh the stored group fields so
            // the stale id does not outlive the merge, and announce the
            // refreshed leader metadata.
            private _info = _participants get _uid;
            _info set ["groupId", _groupId];
            _info set ["groupName", groupId (group _unit)];
            _info set ["groupControlled", true];

            [_record, _groupId] call FUNC(serverRefreshGroupFlag);
            [_record] call FUNC(serverBroadcastRoom);
            continue;
        };

        private _creator = [_record getOrDefault ["createdBy", ""]] call FUNC(getPlayerByUid);
        private _allowed = isNull _creator || {str (side (group _unit)) == str (side (group _creator))};

        if (_allowed && {[_record, _uid] call FUNC(serverStoreRoom)}) then {
            private _info = _participants get _uid;
            _info set ["groupId", _groupId];
            _info set ["groupName", groupId (group _unit)];
            _info set ["groupControlled", true];

            [_record, _groupId] call FUNC(serverRefreshGroupFlag);
            // The room upsert must reach the new participant before the system
            // message: their page only keeps messages for known rooms.
            [_record] call FUNC(serverBroadcastRoom);
            [_record, format ["%1 joined the group chat (in-game group change).", name _unit]] call FUNC(serverGroupSystemMessage);

            if ((_record get "kind") == "group" && {(_record getOrDefault ["inviteKey", ""]) == ""}) then {
                private _sides = +_oldSides;
                { _sides pushBackUnique _x; } forEach ([_record] call FUNC(serverParticipantSides));
                [_sides] call FUNC(serverPushPublicRooms);
            };
        };
    } else {
        if (!(_uid in _participants)) then { continue; };

        // Self-merge: the unit may have left this group for another one that
        // is also tracked for the room; its UnitLeft must not remove it.
        private _liveGroupId = [group _unit] call FUNC(getGroupId);

        if (_liveGroupId != "" && {(_liveGroupId in (keys (_record getOrDefault ["groups", createHashMap])))}) then {
            continue;
        };

        // Side of the leaving participant for the public-room refresh; the
        // record is gone by the time serverDeleteRoom runs.
        private _removedSide = [_uid, _participants get _uid] call FUNC(participantSide);

        _participants deleteAt _uid;
        private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefault [_uid, createHashMap];
        _playerRooms deleteAt (_record get "id");

        if (count _participants == 0) then {
            // The room is deleted; serverDeleteRoom refreshes the public
            // lists of the involved sides itself (the removed UID's side was
            // captured above).
            [_record, [_uid], [_removedSide]] call FUNC(serverDeleteRoom);
        } else {
            [_record, format ["%1 left the group chat (in-game group change).", name _unit]] call FUNC(serverGroupSystemMessage);
            [_record, _groupId] call FUNC(serverRefreshGroupFlag);
            [_record, [_uid]] call FUNC(serverBroadcastRoom);

            if ((_record get "kind") == "group" && {(_record getOrDefault ["inviteKey", ""]) == ""}) then {
                private _sides = +_oldSides;
                { _sides pushBackUnique _x; } forEach ([_record] call FUNC(serverParticipantSides));
                [_sides] call FUNC(serverPushPublicRooms);
            };
        };
    };
} forEach _roomIds;
