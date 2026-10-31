#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Debug-only bridge to the root RemoteAccess extension API, used by the stored
 * remote-share test. It pushes the extension result back to the requesting page
 * because the normal RemoteAccess request is only available to the in-game
 * "local" client.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "action": "start"|"status"|"share"|"stop"|"kick", ... })
 * 1: Sender <OBJECT>
 * 2: Client id <STRING>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["action", "share", "ttlSeconds", 900]], player, "local"] call ace_tacphone_Messaging_fnc_debugRemoteAccess
 *
 * Public: No
 */

params ["_request", "_sender", ["_clientId", ""]];

if (isNull _sender) exitWith {
    createHashMapFromArray [["ok", false], ["error", "No player"]]
};

private _action = toLower (_request getOrDefault ["action", "status"]);
private _subcommand = switch (_action) do {
    case "start": { "Start" };
    case "status": { "Status" };
    case "share": { "ShareCreate" };
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

private _result = [format ["RemoteAccess.%1", _subcommand], _remoteRequest] call EFUNC(tacphone,remoteAccess);

[_sender, createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "Debug.RemoteAccess"],
    ["action", _action],
    ["result", _result]
], _clientId] call FUNC(serverSendPush);

_result
#endif
