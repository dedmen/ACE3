#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Finds the connected player with a given PlayerUID.
 *
 * Fake debug players have no unit and always return objNull.
 *
 * Arguments:
 * 0: Player UID <STRING>
 *
 * Return Value:
 * Player <OBJECT> (objNull when the player is not connected)
 *
 * Example:
 * ["76561198000000000"] call ace_tacphone_Messaging_fnc_getPlayerByUid
 *
 * Public: No
 */

params ["_uid"];

private _result = objNull;

{
    if ((getPlayerUID _x) == _uid) exitWith {
        _result = _x;
    };
} forEach allPlayers;

// Singleplayer/editor: allPlayers can be empty while `player` is valid.
if (isNull _result && {_uid == getPlayerUID player}) then {
    _result = player;
};

_result
