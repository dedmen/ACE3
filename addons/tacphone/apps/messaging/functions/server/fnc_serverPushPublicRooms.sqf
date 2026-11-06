#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Refreshes the public room list of every affected side. For each side the
 * list is built once and pushed as a targeted PublicRooms.State to every
 * online player on that side.
 *
 * A player counts as online on a side when their UID is registered in
 * GVAR(serverPlayerClients) and resolves to a connected player on that side.
 * Sides without any online player are skipped.
 *
 * Arguments:
 * 0: Sides <ARRAY of STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [["WEST"]] call ace_tacphone_Messaging_fnc_serverPushPublicRooms
 *
 * Public: No
 */

params ["_sides"];

{
    private _side = _x;
    private _uids = [];
    private _sample = objNull;

    {
        private _player = [_x] call FUNC(getPlayerByUid);

        if (!isNull _player && {str (side _player) == _side}) then {
            _uids pushBack _x;

            if (isNull _sample) then {
                _sample = _player;
            };
        };
    } forEach (keys GVAR(serverPlayerClients));

    if (_uids isEqualTo []) then {
        continue;
    };

    [_uids, createHashMapFromArray [
        ["a", MESSAGING_APP],
        ["c", "PublicRooms.State"],
        ["rooms", [_sample] call FUNC(serverListPublicRooms)],
        ["now", time]
    ]] call FUNC(serverPushToUids);
} forEach _sides;
