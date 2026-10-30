#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Removes a client from every information interest it holds.
 * Used when a websocket connection goes away, or when an in-game page unloads ("Interest.Clear").
 * Deactivation events fire for the interests that become empty.
 *
 * Arguments:
 * 0: Client id <STRING> ("local" for the in-game browser, a websocket connection id otherwise)
 *
 * Return Value:
 * Number of interests the client was removed from <NUMBER>
 *
 * Example:
 * ["local"] call ace_tacphone_fnc_interestClearClient
 *
 * Public: No
 */

params [["_clientId", ""]];

if (_clientId == "") exitWith { 0 };

if (isNil QGVAR(AppDataInterests)) exitWith { 0 };
if (count GVAR(AppDataInterests) == 0) exitWith { 0 };

private _released = 0;

// Snapshot the names first: interestSet deletes entries that become empty, and a
// HashMap must not be modified while it is being iterated.
{
    if ([_clientId, _x, false] call FUNC(interestSet)) then {
        _released = _released + 1;
    };
} forEach (keys GVAR(AppDataInterests));

_released
