#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * The single boundary to the Messaging app internals for logistics request
 * rooms. "create" builds the Messenger group room of a new request (name
 * "Logistics <id>", kind "group", no targets), makes it public through
 * SetRoomPublic so any same-side player can join it from the queue, and
 * auto-joins every uid of GVAR(serverRoles) that is not a participant yet
 * (one serverBroadcastRoom call after the loop). "addWorker" adds one uid
 * to an existing room.
 *
 * A missing Messaging app, a failed room creation or a failed SetRoomPublic
 * never fail the logistics flow: one diag_log warning and the request
 * continues without a (public) room. Auto-join skips uids whose participant
 * name the Messaging app cannot resolve and still broadcasts the room.
 *
 * The room record is not exposed by a Messaging function, so it is read from
 * the app's room map; every mutation goes through serverStoreRoom and the
 * room is broadcast through serverBroadcastRoom.
 *
 * Arguments:
 * 0: Mode <STRING> ("create" or "addWorker")
 * 1: Request record <HASHMAP> (create) / room id <STRING> (addWorker)
 * 2: Requester player <OBJECT> (create) / worker uid <STRING> (addWorker)
 *
 * Return Value:
 * Room id <STRING> (create; "" when the Messaging app is absent or the
 * creation failed) / added <BOOL> (addWorker)
 *
 * Example:
 * ["create", _record, player] call ace_tacphone_Logistics_fnc_serverRoomAccess
 * ["addWorker", "grp:1_2", "76561198000000000"] call ace_tacphone_Logistics_fnc_serverRoomAccess
 *
 * Public: No
 */

params ["_mode", ["_second", ""], ["_third", objNull]];

private _messagingMissing = isNil "ace_tacphone_Messaging_fnc_serverStoreRoom";

// Flat guard + flag (no nested exitWith): an addWorker that finds the uid
// already in the room is idempotent and returns true without a second store
// or broadcast; a missing room, a missing Messaging app or a non-string uid
// returns false without touching the "create" path below.
if (_mode == "addWorker") exitWith {
    private _added = false;

    if (_second != "" && {!_messagingMissing} && {_third isEqualType ""}) then {
        private _roomRecord = ace_tacphone_Messaging_serverRooms getOrDefault [_second, createHashMap];

        if (count _roomRecord > 0) then {
            private _participants = _roomRecord get "participants";

            if (_third in _participants) then {
                _added = true;
            } else {
                _added = [_roomRecord, _third] call ace_tacphone_Messaging_fnc_serverStoreRoom;

                if (_added) then {
                    [_roomRecord] call ace_tacphone_Messaging_fnc_serverBroadcastRoom;
                };
            };
        };
    };

    _added
};

// "create": the room of a new request, public and with the workers inside.
// The guard must run before any getOrDefault on the record: addWorker passes
// a string, so a wrong _mode must not reach the map access.
if !(_second isEqualType createHashMap) exitWith {
    diag_log format ["[TacPhone Logistics] Room access 'create' expected a request record, got %1", _second];
    ""
};

if (isNil "ace_tacphone_Messaging_fnc_serverCreateRoom" || {isNil "ace_tacphone_Messaging_fnc_serverSetRoomPublic"}) exitWith {
    diag_log format ["[TacPhone Logistics] Messaging app missing, request %1 gets no room", _second getOrDefault ["id", ""]];
    ""
};

private _record = _second;
private _sender = _third;

private _result = [
    createHashMapFromArray [
        ["c", "CreateRoom"],
        ["room", createHashMapFromArray [
            ["name", "Logistics " + (_record getOrDefault ["id", ""])],
            ["kind", "group"]
        ]]
    ],
    _sender
] call ace_tacphone_Messaging_fnc_serverCreateRoom;

// getOrDefault requires a HashMap; a malformed Messaging result must not
// reach it.
if !(_result isEqualType createHashMap) exitWith {
    diag_log format ["[TacPhone Logistics] Room creation returned a non-map for %1", _record getOrDefault ["id", ""]];
    ""
};

if (!(_result getOrDefault ["ok", false])) exitWith {
    diag_log format ["[TacPhone Logistics] Room creation failed for request %1: %2", _record getOrDefault ["id", ""], _result];
    ""
};

private _roomId = _result getOrDefault ["roomId", ""];

if !(_roomId isEqualType "") exitWith {
    diag_log format ["[TacPhone Logistics] Room result has no string id: %1", _result];
    ""
};

if (_roomId == "") exitWith {
    diag_log format ["[TacPhone Logistics] Room creation returned an empty id for %1", _record getOrDefault ["id", ""]];
    ""
};

// Any same-side player can join the room from the queue with an empty key.
// The requester is the room creator, so the creator check inside
// SetRoomPublic passes. A failure keeps the room private (auto-joined
// members can still chat) and is not fatal.
private _publicResult = [
    createHashMapFromArray [
        ["c", "SetRoomPublic"],
        ["roomId", _roomId],
        ["public", true]
    ],
    _sender
] call ace_tacphone_Messaging_fnc_serverSetRoomPublic;

if (!(_publicResult getOrDefault ["ok", false])) then {
    diag_log format ["[TacPhone Logistics] Room %1 stays private, SetRoomPublic failed: %2", _roomId, _publicResult];
};

private _roomRecord = ace_tacphone_Messaging_serverRooms getOrDefault [_roomId, createHashMap];

if (count _roomRecord > 0) then {
    private _participants = _roomRecord get "participants";

    {
        private _uid = _x;

        if (!(_uid in _participants)) then {
            [_roomRecord, _uid] call ace_tacphone_Messaging_fnc_serverStoreRoom;
        };
    } forEach (keys GVAR(serverRoles));

    [_roomRecord] call ace_tacphone_Messaging_fnc_serverBroadcastRoom;
};

_roomId
