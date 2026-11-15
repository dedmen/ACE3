#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Server HandleDisconnect handler: drops the player's logistics role and
 * pushes the removal (role "left"). The player's requests stay in the queue:
 * the requester name is stored on the record, so the rows remain meaningful.
 *
 * No push goes out when the player had no role entry.
 *
 * Arguments:
 * 0: Unit <OBJECT> (disconnecting player)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call ace_tacphone_Logistics_fnc_serverPlayerDisconnected
 *
 * Public: No
 */

params ["_unit"];

private _uid = getPlayerUID _unit;

if (_uid == "" || {!( _uid in GVAR(serverRoles))}) exitWith {};

GVAR(serverRoles) deleteAt _uid;

// The stored requester name is preferred: the unit is gone (or about to be),
// and the name is what the queue rows already show.
private _name = "";

{
    if ((_x getOrDefault ["requesterUid", ""]) == _uid) exitWith {
        _name = _x getOrDefault ["requesterName", ""];
    };
} forEach values GVAR(serverRequests);

if (_name == "") then {
    _name = name _unit;
};

[_uid, "left", _name] call FUNC(serverPushRole);
