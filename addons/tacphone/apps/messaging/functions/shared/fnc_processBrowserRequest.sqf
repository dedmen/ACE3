#include "..\..\script_component.hpp"
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

if (isNil QGVAR(browserRequestHandlers)) then {
    private _handlers = createHashMapFromArray [
        ["Hello", {
            params ["_request", "_clientId", "_uid"];
            private _visible = if (_clientId == "local") then {
                ([_clientId] call FUNC(getLocalPresence)) == "available"
            } else {
                _request getOrDefault ["visible", true]
            };

            GVAR(webClients) set [_clientId, _visible];

            [_uid, _clientId, createHashMapFromArray [
                ["c", "SetClientPresence"],
                ["visible", _visible]
            ]] call FUNC(relayToServer);

            private _presence = ["minimized", "available"] select (true in (values GVAR(webClients)));

            createHashMapFromArray [
                ["ok", true],
                ["self", [_uid, _presence] call FUNC(assembleParticipant)],
                ["serverTime", time],
                ["allowEnemyChat", missionNamespace getVariable [QEGVAR(tacphone,messagingAllowEnemyChat), false]]
            ]
        }],
        ["SetClientPresence", {
            params ["_request", "_clientId", "_uid"];
            private _visible = if (_clientId == "local") then {
                ([_clientId] call FUNC(getLocalPresence)) == "available"
            } else {
                _request getOrDefault ["visible", true]
            };

            GVAR(webClients) set [_clientId, _visible];

            [_uid, _clientId, createHashMapFromArray [
                ["c", "SetClientPresence"],
                ["visible", _visible]
            ]] call FUNC(relayToServer);

            // The server only broadcasts presence to peers; keep this page's
            // own "You" indicator in sync with the effective local/external
            // client set.
            [] call FUNC(clientPushSelfPresence);

            createHashMapFromArray [["ok", true]]
        }]
#ifdef __A3_DEBUG__
        ,
        // Debug commands only work when the server/mission opted in. The check is
        // inside each locally handled debug command, not in the normal request path.
        // Everything else is relayed to the server, which re-checks allowDebug.
        ["Messaging.Debug.Status", {
            params ["_request", "_clientId", "_uid"];
            if (!(missionNamespace getVariable [QEGVAR(tacphone,allowDebug), false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug disabled"]]
            };

            createHashMapFromArray [
                ["ok", true],
                ["debug", true],
                ["app", "Messaging"],
                ["clients", keys GVAR(webClients)],
                ["clientVisibility", GVAR(webClients)],
                ["currentShowMode", EGVAR(tacphone,currentShowMode)],
                ["localPresence", [] call FUNC(getLocalPresence)]
            ]
        }]
#endif
    ];

    GVAR(browserRequestHandlers) = compileFinal _handlers;
};

// Commands without a local handler are relayed to the mission server, which
// answers with pushes. `get` returns an empty array for missing keys, so
// check the key itself.
private _handlers = GVAR(browserRequestHandlers);
if (_command in _handlers) exitWith {
    [_request, _clientId, _uid] call (_handlers get _command);
};

[_uid, _clientId, _request] call FUNC(relayToServer);

createHashMapFromArray [
    ["ok", true],
    ["pending", true]
]
