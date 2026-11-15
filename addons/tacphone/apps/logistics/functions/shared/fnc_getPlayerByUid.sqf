#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Finds the connected player with a given PlayerUID.
 *
 * Scans allPlayers on every call. The queue is event-driven and this only
 * runs on request dispatch, so the scan is cheap enough without a cache.
 *
 * Arguments:
 * 0: Player UID <STRING>
 *
 * Return Value:
 * Player <OBJECT> (objNull when the player is not connected)
 *
 * Example:
 * ["76561198000000000"] call ace_tacphone_Logistics_fnc_getPlayerByUid
 *
 * Public: No
 */

params ["_uid"];

private _player = objNull;

{
    if ((getPlayerUID _x) == _uid) exitWith {
        _player = _x;
    };
} forEach allPlayers;

// Singleplayer/editor: allPlayers can be empty while `player` is valid.
if (isNull _player && {_uid == getPlayerUID player}) then {
    _player = player;
};

_player
