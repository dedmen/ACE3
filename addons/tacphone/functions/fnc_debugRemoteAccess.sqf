#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Debug-only bridge to the root RemoteAccess extension API, used by the stored
 * host runtime tests. The normal RemoteAccess.* command is only available to
 * the in-game "local" client, so a test WebSocket client cannot mint a share
 * link or inspect the relay without this bridge.
 *
 * The caller is also required to have the server-controlled "Allow debug mode"
 * setting enabled; fnc_processBrowserRequest rejects it otherwise.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "action": "start"|"status"|"share"|"revoke"|"stop"|"kick", ... })
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["action", "share", "ttlSeconds", 900]]] call ace_tacphone_fnc_debugRemoteAccess
 *
 * Public: No
 */

params ["_request"];

private _action = toLower (_request getOrDefault ["action", "status"]);
private _subcommand = switch (_action) do {
    case "start": { "Start" };
    case "status": { "Status" };
    case "share": { "ShareCreate" };
    case "revoke": { "ShareRevoke" };
    case "stop": { "Stop" };
    case "kick": { "Kick" };
    default { "" };
};

if (_subcommand == "") exitWith {
    createHashMapFromArray [["ok", false], ["error", "Unknown remote access action"]]
};

private _remoteRequest = createHashMapFromArray [
    ["ttlSeconds", _request getOrDefault ["ttlSeconds", 900]],
    ["peerId", _request getOrDefault ["peerId", ""]]
];

[format ["RemoteAccess.%1", _subcommand], _remoteRequest] call FUNC(remoteAccess);
#endif
