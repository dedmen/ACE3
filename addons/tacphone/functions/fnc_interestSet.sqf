#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Adds or removes a client from a named information interest.
 * Fires GVAR(interestActivated) / GVAR(interestDeactivated) only on real transitions,
 * that is when the first client joins or the last client leaves the interest.
 *
 * Arguments:
 * 0: Client id <STRING> ("local" for the in-game browser, a websocket connection id otherwise)
 * 1: Interest name <STRING> (max 128 characters, namespaced like "ACE_TacPhone_Map.markers")
 * 2: Active <BOOL> (true to add the client, false to remove it)
 *
 * Return Value:
 * State changed <BOOL> (false for a duplicate set, invalid input, or removing something not held)
 *
 * Example:
 * ["local", "ACE_TacPhone_Map.markers", true] call ace_tacphone_fnc_interestSet
 *
 * Public: No
 */

params [["_clientId", ""], ["_interest", ""], ["_active", false]];

if (_clientId == "" || {_interest == ""}) exitWith {
    diag_log format ["[TacPhone] Invalid interestSet arguments: %1", [_clientId, _interest, _active]];
    false
};

private _entry = GVAR(AppDataInterests) get _interest;

if (_active) exitWith {
    // Entry is created lazily, an interest nobody ever held costs nothing
    if (isNil "_entry") then {
        _entry = createHashMap;
        _entry set ["clients", createHashMap];
        _entry set ["active", false];
        GVAR(AppDataInterests) set [_interest, _entry];
    };

    private _clients = _entry get "clients";
    private _changed = false;

    // Membership is a set, so duplicate sets are no-ops and never fire an event
    if (!(_clients getOrDefault [_clientId, false])) then {
        _clients set [_clientId, true];
        _changed = true;

        if (!(_entry get "active")) then {
            _entry set ["active", true];
            [QGVAR(interestActivated), [_interest]] call CBA_fnc_localEvent;
            //#TODO remove debug logging (tracked in TODO.md)
            systemChat format ["[TacPhone] Interest activated: %1 (client %2)", _interest, _clientId];
        };
    };

    _changed
};

if (isNil "_entry") exitWith { false }; // Interest unknown, nothing was held

private _clients = _entry get "clients";

if (!(_clients getOrDefault [_clientId, false])) exitWith { false }; // Client did not hold it, no-op

_clients deleteAt _clientId;

if (count _clients > 0) exitWith { true };

// Last client left, the interest is deactivated and its entry is dropped again
_entry set ["active", false];
[QGVAR(interestDeactivated), [_interest]] call CBA_fnc_localEvent;
//#TODO remove debug logging (tracked in TODO.md)
systemChat format ["[TacPhone] Interest deactivated: %1 (client %2)", _interest, _clientId];

// Only drop the entry if it is still empty: an event handler may have acquired the interest again
if (count _clients == 0) then {
    GVAR(AppDataInterests) deleteAt _interest;
};

true
