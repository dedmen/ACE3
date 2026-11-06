#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Makes a group room public or private. Public means an empty invite key, so
 * any same-side player can find the room in the public list and join it
 * without an invite; private regenerates a fresh invite key, which invalidates
 * invites sent earlier. Only the room creator may toggle.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "SetRoomPublic", "roomId": "", "public": true })
 * 1: Sender <OBJECT> (player toggling the room)
 *
 * Return Value:
 * Result <HASHMAP> ({ok, roomId, pending})
 *
 * Example:
 * [_request, player] call ace_tacphone_Messaging_fnc_serverSetRoomPublic
 *
 * Public: No
 */

params ["_request", "_sender"];

REQUIRE_SENDER(_sender);

private _roomId = _request getOrDefault ["roomId", ""];
private _record = createHashMap;
ROOM_OR_ERROR(_record,_roomId,"Room not found");

if ((_record get "kind") != "group") exitWith {
    createHashMapFromArray [["ok", false], ["error", "Only group rooms can be public"]]
};

if (getPlayerUID _sender != (_record getOrDefault ["createdBy", ""])) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Only the room creator can change the public state"]]
};

if (_request getOrDefault ["public", false]) then {
    // An empty invite key makes the room joinable by any same-side player.
    _record set ["inviteKey", ""];
} else {
    // A fresh key: earlier invites keep the old key and stop working.
    _record set ["inviteKey", format ["%1-%2", round (random 999999), round (random 999999)]];
};

[_record] call FUNC(serverBroadcastRoom);
[[ _record ] call FUNC(serverParticipantSides)] call FUNC(serverPushPublicRooms);

createHashMapFromArray [["ok", true], ["roomId", _roomId], ["pending", true]]
