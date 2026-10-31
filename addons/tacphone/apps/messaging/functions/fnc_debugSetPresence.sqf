#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Forces the presence of a fake or real player for tests and broadcasts the
 * change to the players sharing a room with it. Only compiled into builds made
 * with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "uid": "", "presence": "available" })
 * 1: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["uid", "fake_1"], ["presence", "available"]], player] call ace_tacphone_Messaging_fnc_debugSetPresence
 *
 * Public: No
 */

params ["_request", "_sender"];

private _uid = _request getOrDefault ["uid", ""];
private _presence = _request getOrDefault ["presence", MESSAGING_PRESENCE_OFFLINE];

if (!(_presence in [MESSAGING_PRESENCE_AVAILABLE, MESSAGING_PRESENCE_MINIMIZED, MESSAGING_PRESENCE_OFFLINE])) then {
    _presence = MESSAGING_PRESENCE_OFFLINE;
};

if (_uid == "") exitWith {
    createHashMapFromArray [["ok", false], ["error", "Missing uid"]]
};

GVAR(serverPlayerPresence) set [_uid, _presence];
[_uid, _presence] call FUNC(serverBroadcastPresence);
[_sender] call FUNC(serverPushPlayerList);

createHashMapFromArray [
    ["ok", true],
    ["uid", _uid],
    ["presence", _presence]
]
#endif
