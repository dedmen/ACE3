#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Handles requests sent by the Logistics panel.
 *
 * The queue and the player roles are server-authoritative, so nothing is
 * answered locally: every command, including the Debug.* commands (which the
 * server re-checks against ace_tacphone_allowDebug), is relayed to the
 * mission server and answered there with pushes. The relayed commands
 * therefore reply with {ok: true, pending: true}.
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "a": "ACE_TacPhone_Logistics", "c": "CreateRequest", ... })
 * 1: Client id <STRING> ("local" in-game, a WebSocket id remotely)
 *
 * Return Value:
 * Result <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["a", "ACE_TacPhone_Logistics"], ["c", "GetLogisticsState"]]] call ace_tacphone_Logistics_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request", "_clientId"];

private _uid = getPlayerUID player;

[_uid, _clientId, _request] call FUNC(relayToServer);

createHashMapFromArray [
    ["ok", true],
    ["pending", true]
]
