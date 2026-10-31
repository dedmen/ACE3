#include "..\script_component.hpp"
#ifdef __A3_DEBUG__
/*
 * Author: Dedmen
 * Dispatches the debug-only Messaging.Debug.* commands. Only compiled into
 * builds made with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Request <HASHMAP>
 * 1: Command <STRING>
 * 2: Sender <OBJECT>
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [_request, "Messaging.Debug.Status", player] call ace_tacphone_Messaging_fnc_debugHandleRequest
 *
 * Public: No
 */

params ["_request", "_command", "_sender", ["_clientId", ""]];

switch (_command) do {
    case "Messaging.Debug.AddFakePlayers": {
        [_request, _sender] call FUNC(debugAddFakePlayers)
    };
    case "Messaging.Debug.Reset": {
        [_request, _sender] call FUNC(debugReset)
    };
    case "Messaging.Debug.InjectMessage": {
        [_request, _sender] call FUNC(debugInjectMessage)
    };
    case "Messaging.Debug.GroupUnit": {
        [_request, _sender] call FUNC(debugGroupUnit)
    };
    case "Messaging.Debug.AIGroup": {
        [_request, _sender] call FUNC(debugAIGroup)
    };
    case "Messaging.Debug.RoomInfo": {
        [_request, _sender, _clientId] call FUNC(debugRoomInfo)
    };
    case "Messaging.Debug.RemoteAccess": {
        [_request, _sender, _clientId] call FUNC(debugRemoteAccess)
    };
    case "Messaging.Debug.SetAllowEnemyChat": {
        [_request, _sender] call FUNC(debugSetAllowEnemyChat)
    };
    case "Messaging.Debug.SetPresence": {
        [_request, _sender] call FUNC(debugSetPresence)
    };
    case "Messaging.Debug.SaveState": {
        [_request, _sender] call FUNC(debugSaveState)
    };
    case "Messaging.Debug.LoadState": {
        [_request, _sender] call FUNC(debugLoadState)
    };
    default {
        createHashMapFromArray [["ok", false], ["error", format ["Unknown debug command: %1", _command]]]
    };
}
#endif
