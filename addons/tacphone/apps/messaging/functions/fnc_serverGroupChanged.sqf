#include "..\script_component.hpp"
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

private _roomIds = keys (GVAR(groupRooms) getOrDefault [_groupId, createHashMap]);

{
    private _record = GVAR(serverRooms) getOrDefault [_x, createHashMap];
    if (count _record == 0) then { continue; };

    private _participants = _record get "participants";

    if (_event == "joined") then {
        if (_uid in _participants) then { continue; };

        private _creator = [_record getOrDefault ["createdBy", ""]] call FUNC(getPlayerByUid);
        private _allowed = isNull _creator || {str (side _unit) == str (side _creator)};

        if (_allowed && {[_record, _uid] call FUNC(serverAddParticipantToRoom)}) then {
            private _info = _participants get _uid;
            _info set ["groupId", _groupId];
            _info set ["groupName", groupId (group _unit)];
            _info set ["groupControlled", true];

            [_record, format ["%1 joined the group chat (in-game group change).", name _unit]] call FUNC(serverGroupSystemMessage);
            [_record, _groupId] call FUNC(serverRefreshGroupFlag);
            [_record] call FUNC(serverBroadcastRoom);
        };
    } else {
        if (!(_uid in _participants)) then { continue; };

        _participants deleteAt _uid;
        private _playerRooms = GVAR(serverRoomsByPlayer) getOrDefault [_uid, createHashMap];
        _playerRooms deleteAt (_record get "id");

        if (count _participants == 0) then {
            [_record, [_uid]] call FUNC(serverDeleteRoom);
        } else {
            [_record, format ["%1 left the group chat (in-game group change).", name _unit]] call FUNC(serverGroupSystemMessage);
            [_record, _groupId] call FUNC(serverRefreshGroupFlag);
            [_record, [_uid]] call FUNC(serverBroadcastRoom);
        };
    };
} forEach _roomIds;
