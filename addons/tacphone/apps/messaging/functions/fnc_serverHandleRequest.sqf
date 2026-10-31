#include "..\script_component.hpp"
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

#ifdef __A3_DEBUG__
if ((_command find "Messaging.Debug.") == 0) exitWith {
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
    case "RegisterClient";
    case "SetClientPresence": {
        [_sender, _clientId, _request getOrDefault ["visible", false]] call FUNC(serverSetClientPresence);
        _result set ["ok", true];
    };
    case "ClientDisconnect": {
        [_clientId] call FUNC(clientRemoveClient);
        _result set ["ok", true];
    };
    case "CreateRoom": {
        _result = [_request, _sender] call FUNC(serverCreateRoom);
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

    [_sender, _errorPush, _clientId] call FUNC(serverSendPush);
};

_result
