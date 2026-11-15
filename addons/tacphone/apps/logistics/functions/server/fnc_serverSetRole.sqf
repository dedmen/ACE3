#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Sets a player's logistics role (player/worker) in GVAR(serverRoles) and
 * pushes the change. Switching to worker also adds the player to every open
 * request room (state not done/cancelled); switching back to player only
 * drops the role entry, because Messenger has no leave-room command.
 *
 * _uidOverride and _nameOverride are "" on the normal path. The debug role
 * setter passes them for players the server cannot resolve (fake players).
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "c": "SetRole", "role": "player"|"worker" })
 * 1: Sender <OBJECT> (player setting the role; may be null with a uid override)
 * 2: UID override <STRING> (default "", the sender's PlayerUID)
 * 3: Name override <STRING> (default "", used when no name is known)
 *
 * Return Value:
 * Result <HASHMAP> ({ok: true, pending: true} on a real change; {ok: true}
 * without a push when the role is not one of the two values or is unchanged)
 *
 * Note: the stored web option is a per-device preference; the server role
 * follows the last accepted SetRole (per-account roles are out of scope).
 *
 * Example:
 * [_request, player, "", ""] call ace_tacphone_Logistics_fnc_serverSetRole
 *
 * Public: No
 */

params ["_request", "_sender", ["_uidOverride", ""], ["_nameOverride", ""]];

private _role = _request getOrDefault ["role", ""];

// The payload is JSON, so a well-formed request carries a string. `str` would
// wrap it in quotes ("worker" -> len 8); coerce instead of converting.
if !(_role isEqualType "") then {
    _role = "";
};

if (_role != "player" && {_role != "worker"}) exitWith {
    createHashMapFromArray [["ok", true]]
};

private _uid = _uidOverride;

if (_uid == "" && {!isNull _sender}) then {
    _uid = getPlayerUID _sender;
};

if (_uid == "") exitWith {
    createHashMapFromArray [["ok", true]]
};

// M-8: an unchanged role (the stored option is a per-device preference, the
// server role follows the last accepted SetRole) is a no-op: no room scan,
// no push. An absent entry counts as "player", so a player-role reconnect
// does not re-push either.
private _current = GVAR(serverRoles) getOrDefault [_uid, "player"];

if (_current == _role) exitWith {
    createHashMapFromArray [["ok", true]]
};

if (_role == "worker") then {
    GVAR(serverRoles) set [_uid, "worker"];

    // A new worker joins every open request room. Finished and cancelled
    // requests are never touched, and rooms of requests without a Messaging
    // room stay empty.
    {
        private _state = _x getOrDefault ["state", ""];
        private _roomId = _x getOrDefault ["roomId", ""];

        if (_roomId != "" && {_state != LOGISTICS_STATE_DONE} && {_state != LOGISTICS_STATE_CANCELLED}) then {
            ["addWorker", _roomId, _uid] call FUNC(serverRoomAccess);
        };
    } forEach values GVAR(serverRequests);
} else {
    GVAR(serverRoles) deleteAt _uid;
};

// The stored requester name is preferred: it is what the queue rows show and
// it stays stable if the unit is gone. The override covers debug uids the
// server cannot resolve, then the sender's own name.
private _name = "";

{
    if ((_x getOrDefault ["requesterUid", ""]) == _uid) exitWith {
        _name = _x getOrDefault ["requesterName", ""];
    };
} forEach values GVAR(serverRequests);

if (_name == "") then {
    if (_nameOverride != "") then {
        _name = _nameOverride;
    } else {
        _name = if (isNull _sender) then { "" } else { name _sender };
    };
};

[_uid, _role, _name] call FUNC(serverPushRole);

createHashMapFromArray [["ok", true], ["pending", true]]
