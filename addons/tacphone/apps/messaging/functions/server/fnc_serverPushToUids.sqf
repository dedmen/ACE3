#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Pushes one push to the page clients of every player in a UID list. UIDs of
 * players that are not connected (or fake debug players) are skipped.
 *
 * Arguments:
 * 0: Player UIDs <ARRAY of STRING>
 * 1: Push <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [keys (_record get "participants"), _push] call ace_tacphone_Messaging_fnc_serverPushToUids
 *
 * Public: No
 */

params ["_uids", "_push"];

{
    private _player = [_x] call FUNC(getPlayerByUid);

    if (!isNull _player) then {
        [_player, _push] call FUNC(serverSendPush);
    };
} forEach _uids;
