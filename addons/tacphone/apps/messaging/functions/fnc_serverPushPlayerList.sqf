#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the player list for one player and pushes it as PlayerList.State.
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call ace_tacphone_Messaging_fnc_serverPushPlayerList
 *
 * Public: No
 */

params ["_player"];

private _list = [_player] call FUNC(getPlayerList);

[_player, createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "PlayerList.State"],
    ["players", _list getOrDefault ["players", []]],
    ["groups", _list getOrDefault ["groups", []]],
    ["allowEnemyChat", _list getOrDefault ["allowEnemyChat", false]]
]] call FUNC(serverSendPush);
