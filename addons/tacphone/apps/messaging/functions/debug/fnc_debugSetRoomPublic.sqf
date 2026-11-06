#include "..\..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Debug-only version of fnc_serverSetRoomPublic without the creator check, so
 * the test suite can toggle rooms it did not create. Same behaviour otherwise:
 * keeps the room-not-found and non-group checks, clears or regenerates the
 * invite key, then pushes Room.Upsert and the public room list.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "Messaging.Debug.SetRoomPublic", "roomId": "", "public": true })
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP> ({ok, roomId, pending})
 *
 * Example:
 * [_request, player] call ace_tacphone_Messaging_fnc_debugSetRoomPublic
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
#endif
