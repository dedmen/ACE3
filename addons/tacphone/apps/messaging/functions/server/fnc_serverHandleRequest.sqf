#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Server entry point for requests relayed by a client. Validates the command,
 * dispatches to the matching fnc_server* handler and pushes an Error to the
 * requesting player when the command failed.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "a": "Messaging", "c": "CreateRoom", ... })
 * 1: Client id <STRING> (page client that sent the request)
 * 2: Sender <OBJECT> (player whose client relayed the request)
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["c", "RequestChatState"]], "local", player] call ace_tacphone_Messaging_fnc_serverHandleRequest
 *
 * Public: No
 */

params ["_request", "_clientId", "_sender"];

if (!isServer) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Not the server"]]
};

if (!(_request isEqualType createHashMap)) exitWith {
    createHashMapFromArray [["ok", false], ["error", "Invalid request"]]
};

private _command = _request getOrDefault ["c", ""];
private _result = createHashMapFromArray [["ok", false]];

// One participant cache scope per request: the dispatch runs to completion
// without yielding, so the cached participant and public list data (O3/O2)
// stays valid for the whole run.
[] call FUNC(serverBeginParticipantScope);

#ifdef __A3_DEBUG__
// Debug commands are opt-in twice: __A3_DEBUG__ here and the server/mission
// allowDebug setting. The whole check and dispatch compile out in release.
if ((_command find "Messaging.Debug.") == 0) exitWith {
    if (!(missionNamespace getVariable [QEGVAR(tacphone,allowDebug), false])) exitWith {
        createHashMapFromArray [["ok", false], ["error", "debug disabled"]]
    };
    [_request, _command, _sender, _clientId] call FUNC(debugHandleRequest)
};
#endif

switch (_command) do {
    case "GetPlayerList": {
        [_sender] call FUNC(serverPushPlayerList);
        _result set ["ok", true];
    };
    case "RequestChatState": {
        [_sender] call FUNC(serverSync);
        _result set ["ok", true];
    };
    case "SetClientPresence": {
        // A registering client is visible by default, matching the local
        // handler default in FUNC(processBrowserRequest).
        [_sender, _clientId, _request getOrDefault ["visible", true]] call FUNC(serverSetClientPresence);
        _result set ["ok", true];
    };
    case "ClientDisconnect": {
        [_clientId] call FUNC(clientRemoveClient);
        _result set ["ok", true];
    };
    case "CreateRoom": {
        _result = [_request, _sender] call FUNC(serverCreateRoom);
    };
    case "SetRoomPublic": {
        _result = [_request, _sender] call FUNC(serverSetRoomPublic);
    };
    case "AddParticipants": {
        _result = [_request, _sender] call FUNC(serverAddParticipants);
    };
    case "RemoveParticipants": {
        _result = [_request, _sender] call FUNC(serverRemoveParticipants);
    };
    case "SendMessage": {
        _result = [_request, _sender] call FUNC(serverHandleNewMessage);
    };
    case "ForwardMessage": {
        _result = [_request, _sender] call FUNC(serverForwardMessage);
    };
    case "InviteToRoom": {
        _result = [_request, _sender] call FUNC(serverInviteToRoom);
    };
    case "JoinRoom": {
        _result = [_request, _sender] call FUNC(serverJoinRoom);
    };
    case "GetPublicRooms": {
        // A sender resolved from a relayed UID can be objNull when the player
        // disconnects mid-relay; there is nobody to push to, so the request
        // fails like any other rejected one (the REQUIRE_SENDER macro would
        // only exit this case block, leaving the stale result behind).
        if (isNull _sender) then {
            _result set ["error", "No player"];
        } else {
            [[str (side (group _sender))]] call FUNC(serverPushPublicRooms);
            _result set ["ok", true];
            _result set ["pending", true];
        };
    };
    default {
        _result set ["error", format ["Unknown Messaging command: %1", _command]];
    };
};

if (!(_result getOrDefault ["ok", false]) && {!isNull _sender}) then {
    private _errorPush = createHashMapFromArray [
        ["a", MESSAGING_APP],
        ["c", "Error"],
        ["request", _command],
        ["message", _result getOrDefault ["error", "Request failed"]]
    ];

    private _clientMessageId = _request getOrDefault ["clientMessageId", ""];
    if (_clientMessageId != "") then {
        _errorPush set ["clientMessageId", _clientMessageId];
    };

    // Lets the page attribute the failure to one in-flight request instead of
    // failing every pending one: any command that carries a room id (JoinRoom,
    // AddParticipants, RemoveParticipants, SetRoomPublic) echoes it back.
    private _roomId = _request getOrDefault ["roomId", ""];
    if (_roomId != "") then {
        _errorPush set ["roomId", _roomId];
    };

    [_sender, _errorPush, _clientId] call FUNC(serverSendPush);
};

_result
