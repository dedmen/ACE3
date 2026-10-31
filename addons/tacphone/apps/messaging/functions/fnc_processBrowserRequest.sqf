#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Handles requests sent by the Messenger panel.
 *
 * `Hello` and `SetClientPresence` are answered locally: the page client is
 * registered on this machine and its visibility is reported to the server.
 * Every other command is relayed to the mission server, which answers with
 * pushes. The relayed commands therefore reply with {ok: true, pending: true}.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "a": "Messaging", "c": "Hello", ... })
 * 1: Client id <STRING> ("local" in-game, a WebSocket id remotely)
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["a", "Messaging"], ["c", "Hello"]]] call ace_tacphone_Messaging_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request", "_clientId"];

private _command = _request getOrDefault ["c", ""];
private _uid = getPlayerUID player;

if (_command == "Hello") exitWith {
    private _visible = if (_clientId == "local") then {
        ([_clientId] call FUNC(getLocalPresence)) == MESSAGING_PRESENCE_AVAILABLE
    } else {
        _request getOrDefault ["visible", true]
    };

    GVAR(webClients) set [_clientId, _visible];

    [_uid, _clientId, createHashMapFromArray [
        ["c", "SetClientPresence"],
        ["visible", _visible]
    ]] call FUNC(relayToServer);

    private _presence = [MESSAGING_PRESENCE_MINIMIZED, MESSAGING_PRESENCE_AVAILABLE] select (true in (values GVAR(webClients)));

    createHashMapFromArray [
        ["ok", true],
        ["self", [_uid, _presence] call FUNC(assembleParticipant)],
        ["serverTime", time],
        ["allowEnemyChat", missionNamespace getVariable [QEGVAR(tacphone,messagingAllowEnemyChat), false]]
    ]
};

if (_command == "SetClientPresence") exitWith {
    private _visible = if (_clientId == "local") then {
        ([_clientId] call FUNC(getLocalPresence)) == MESSAGING_PRESENCE_AVAILABLE
    } else {
        _request getOrDefault ["visible", true]
    };

    GVAR(webClients) set [_clientId, _visible];

    [_uid, _clientId, createHashMapFromArray [
        ["c", "SetClientPresence"],
        ["visible", _visible]
    ]] call FUNC(relayToServer);

    // The server only broadcasts presence to peers; keep this page's own
    // indicator in sync with the effective local/external client set.
    if (_uid != "") then {
        private _presence = [MESSAGING_PRESENCE_MINIMIZED, MESSAGING_PRESENCE_AVAILABLE] select (true in (values GVAR(webClients)));

        [createHashMapFromArray [
            ["a", MESSAGING_APP],
            ["c", "Presence.Changed"],
            ["uid", _uid],
            ["presence", _presence],
            ["now", time]
        ]] call FUNC(clientPushToWeb);
    };

    createHashMapFromArray [["ok", true]]
};

#ifdef __A3_DEBUG__
// Debug commands that only make sense on the machine with the page.
if (_command == "Messaging.Debug.Status") exitWith {
    createHashMapFromArray [
        ["ok", true],
        ["debug", true],
        ["app", MESSAGING_APP],
        ["clients", keys GVAR(webClients)],
        ["clientVisibility", GVAR(webClients)],
        ["currentShowMode", EGVAR(tacphone,currentShowMode)],
        ["localPresence", [] call FUNC(getLocalPresence)],
        ["selfPresence", [_uid] call FUNC(getPresence)]
    ]
};

if (_command == "Messaging.Debug.SetLocalDisplayMode") exitWith {
    [_request getOrDefault ["mode", ""]] call FUNC(debugSetLocalDisplayMode)
};
#endif

[_uid, _clientId, _request] call FUNC(relayToServer);

createHashMapFromArray [
    ["ok", true],
    ["pending", true]
]
