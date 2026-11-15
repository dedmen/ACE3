#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Sends the one-off Vehicle.Airdrop push to all phone clients: what the game
 * did with an airdrop (inProgress, dropped, cancelled), so the phone UI can
 * mirror the in-game progress bar and block its buttons while a drop runs.
 * Like Vehicle.Changed this is not interest-gated; the game always tells the
 * phones what happened.
 *
 * Arguments:
 * 0: State <STRING> ("inProgress", "dropped" or "cancelled")
 * 1: Item id <STRING> (netId of the dropped object, or its classname)
 * 2: Duration <NUMBER> (optional, drop duration in seconds, sent when > 0)
 * 3: Error <STRING> (optional, machine-readable cancel reason, sent when not empty)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["inProgress", "123", 15] call ace_tacphone_vehicle_fnc_pushAirdrop
 *
 * Public: No
 */

params ["_state", "_itemId", ["_duration", 0], ["_error", ""]];

private _update = createHashMapFromArray [
    ["a", "ACE_TacPhone_Vehicle"],
    ["c", "Vehicle.Airdrop"],
    ["state", _state],
    ["item", _itemId]
];

if (_duration > 0) then {
    _update set ["duration", _duration];
};
if (_error isNotEqualTo "") then {
    _update set ["error", _error];
};

[_update] call EFUNC(tacphone,sendCommandToPhone);
