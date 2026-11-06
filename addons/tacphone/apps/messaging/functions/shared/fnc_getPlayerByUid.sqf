#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Finds the connected player with a given PlayerUID.
 *
 * Uses the uid -> player cache GVAR(serverPlayerByUid) (missionNamespace)
 * instead of scanning allPlayers on every call, which matters on the hot
 * paths (room assembly and broadcast). Entries are removed in
 * FUNC(serverPlayerDisconnected) when a player leaves. A cache miss (or a
 * stale entry of a deleted unit) falls back to the allPlayers scan and
 * refreshes the cache, so joins are picked up lazily on first use and a
 * reconnect with the same UID self-heals.
 *
 * The cache is created lazily on first use, because the app's variable
 * initialisation lives in XEH_preInit.
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

private _cache = GVAR(serverPlayerByUid);

if (isNil "_cache") then {
    _cache = createHashMap;
    GVAR(serverPlayerByUid) = _cache;
};

private _player = _cache getOrDefault [_uid, objNull];

if (isNull _player) then {
    // Cache miss or stale entry: scan and refresh.
    {
        if ((getPlayerUID _x) == _uid) exitWith {
            _player = _x;
        };
    } forEach allPlayers;

    // Singleplayer/editor: allPlayers can be empty while `player` is valid.
    if (isNull _player && {_uid == getPlayerUID player}) then {
        _player = player;
    };

    if (!isNull _player) then {
        _cache set [_uid, _player];
    };
};

_player
