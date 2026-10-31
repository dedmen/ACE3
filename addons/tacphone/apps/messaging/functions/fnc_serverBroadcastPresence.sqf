#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Pushes Presence.Changed to every online player that shares at least one room
 * with the player whose presence changed.
 *
 * Arguments:
 * 0: Player UID <STRING>
 * 1: Presence <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["76561198000000000", "minimized"] call ace_tacphone_Messaging_fnc_serverBroadcastPresence
 *
 * Public: No
 */

params ["_uid", "_presence"];

private _rooms = GVAR(serverRoomsByPlayer) getOrDefault [_uid, createHashMap];

if (count _rooms == 0) exitWith {};

private _notified = createHashMap;
private _push = createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "Presence.Changed"],
    ["uid", _uid],
    ["presence", _presence]
];

{
    {
        private _otherUid = _x;

        if (_otherUid != _uid && {!(_otherUid in _notified)}) then {
            _notified set [_otherUid, true];

            private _player = [_otherUid] call FUNC(getPlayerByUid);

            if (!isNull _player) then {
                [_player, _push] call FUNC(serverSendPush);
            };
        };
    } forEach (keys (_x get "participants"));
} forEach (values _rooms);
