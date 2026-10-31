#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Appends a system message to a room and pushes it to every participant.
 *
 * Arguments:
 * 0: Room record <HASHMAP>
 * 1: Text <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_record, "Bob joined the group chat (in-game group change)."] call ace_tacphone_Messaging_fnc_serverGroupSystemMessage
 *
 * Public: No
 */

params ["_record", "_text"];

private _message = createHashMapFromArray [
    ["id", ["msg:"] call FUNC(generateId)],
    ["roomId", _record get "id"],
    ["senderUid", ""],
    ["senderName", ""],
    ["content", _text],
    ["objects", []],
    ["timestamp", time],
    ["system", true]
];

(_record get "messages") pushBack _message;
[_message, _record] call FUNC(serverPushMessage);
