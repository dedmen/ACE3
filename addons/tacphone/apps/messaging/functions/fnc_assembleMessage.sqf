#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds a stored message keeping the sender's name, group id, group name and
 * group colour at send time. Optional fields (clientMessageId, forwarded) are
 * only added when they are present, matching the wire contract.
 *
 * Arguments:
 * 0: Message data <HASHMAP> (id, roomId, content, objects, optional senderUid,
 *    clientMessageId, forwarded)
 * 1: Sender <OBJECT> (objNull for a fake debug sender, then senderUid is used)
 *
 * Return Value:
 * Message <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["id", "msg:1"], ["roomId", "grp:1_2"]], player] call ace_tacphone_Messaging_fnc_assembleMessage
 *
 * Public: No
 */

params ["_messageData", "_sender"];

private _uid = _messageData getOrDefault ["senderUid", ""];

if (!isNull _sender) then {
    _uid = getPlayerUID _sender;
};

private _senderInfo = [_uid] call FUNC(assembleParticipant);

private _message = createHashMapFromArray [
    ["id", _messageData getOrDefault ["id", ""]],
    ["roomId", _messageData getOrDefault ["roomId", ""]],
    ["senderUid", _uid],
    ["senderName", _senderInfo getOrDefault ["name", ""]],
    ["content", _messageData getOrDefault ["content", ""]],
    ["objects", _messageData getOrDefault ["objects", []]],
    ["timestamp", _messageData getOrDefault ["timestamp", time]]
];

private _groupId = _senderInfo getOrDefault ["groupId", ""];
if (_groupId != "") then {
    _message set ["senderGroupId", _groupId];
    _message set ["senderGroupName", _senderInfo getOrDefault ["groupName", _groupId]];

    private _groupColor = _senderInfo getOrDefault ["groupColor", ""];
    if (_groupColor != "") then {
        _message set ["senderGroupColor", _groupColor];
    };
};

private _clientMessageId = _messageData getOrDefault ["clientMessageId", ""];
if (_clientMessageId != "") then {
    _message set ["clientMessageId", _clientMessageId];
};

private _forwarded = _messageData getOrDefault ["forwarded", createHashMap];
if (count _forwarded > 0) then {
    _message set ["forwarded", _forwarded];
};

_message
