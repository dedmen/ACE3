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
 * The registered UIDs are bucketed by side in a single pass (O1): each
 * player is resolved once instead of once per affected side.
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

private _bySide = createHashMap;

{
    private _uid = _x;
    private _player = [_uid] call FUNC(getPlayerByUid);

    if (isNull _player) then { continue; };

    private _side = str (side (group _player));
    private _uids = _bySide getOrDefault [_side, []];
    _uids pushBack _uid;
    _bySide set [_side, _uids];
} forEach (keys GVAR(serverPlayerClients));

{
    private _uids = _bySide getOrDefault [_x, []];

    if (_uids isEqualTo []) then {
        continue;
    };

    // Resolved again from the cache (O(1)) just to hand a player object to
    // the list builder; it was confirmed connected in the pass above.
    private _sample = [_uids select 0] call FUNC(getPlayerByUid);

    [_uids, createHashMapFromArray [
        ["a", MESSAGING_APP],
        ["c", "PublicRooms.State"],
        ["rooms", [_sample] call FUNC(serverListPublicRooms)],
        ["now", time]
    ]] call FUNC(serverPushToUids);
} forEach _sides;
