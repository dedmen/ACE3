#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Pushes one already-assembled message to every online participant of a room.
 *
 * Arguments:
 * 0: Message <HASHMAP>
 * 1: Room record <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_message, _record] call ace_tacphone_Messaging_fnc_serverPushMessage
 *
 * Public: No
 */

params ["_message", "_room"];

private _push = createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "Message.New"],
    ["message", _message]
];

[keys (_room get "participants"), _push] call FUNC(serverPushToUids);
