#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Side restriction check for new rooms, participant additions, invites and
 * joins. Uses the global messagingAllowEnemyChat setting, or the debug override
 * when the addon was built with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Sender <OBJECT>
 * 1: Target UID <STRING>
 *
 * Return Value:
 * Allowed <BOOL>
 *
 * Example:
 * [player, "76561198000000000"] call ace_tacphone_Messaging_fnc_serverCanChat
 *
 * Public: No
 */

params ["_sender", "_targetUid"];

if (isNull _sender) exitWith { false };
if (_targetUid == "") exitWith { false };
if (_targetUid == (getPlayerUID _sender)) exitWith { true };

private _allowEnemyChat = missionNamespace getVariable [QEGVAR(tacphone,messagingAllowEnemyChat), false];

#ifdef __A3_DEBUG__
if (!isNil QGVAR(debugAllowEnemyChat)) then {
    _allowEnemyChat = GVAR(debugAllowEnemyChat);
};
#endif

if (_allowEnemyChat) exitWith { true };

private _targetInfo = [_targetUid] call FUNC(assembleParticipant);

if ((_targetInfo getOrDefault ["name", ""]) == "") exitWith { false };

(str (side _sender)) == (_targetInfo getOrDefault ["side", ""])
