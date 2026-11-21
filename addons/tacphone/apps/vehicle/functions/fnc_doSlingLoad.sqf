#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Attaches or releases the sling-load hook. Attach picks the first
 * (nearest) candidate the shared scan (fnc_scanSlingTargets) marks as
 * slingloadable, so the scope and the Hook agree on the pick; release
 * detaches any cargo.
 *
 * Arguments:
 * 0: Vehicle <OBJECT> (the helicopter)
 * 1: State <BOOL> (true = attach, false = release)
 *
 * Return Value:
 * ARRAY [true, cargoNetId] on success ("" when releasing), [false, "error"] on failure
 *
 * Example:
 * [vehicle player, true] call ace_tacphone_vehicle_fnc_doSlingLoad
 *
 * Public: No
 */

params ["_vehicle", "_state"];

if (_state) then {
    // The shared scan (scope payload and Hook pick agree on the pick) is
    // nearest first and carries the hook's real verdict per pair: the game's
    // canSlingLoad AND the native attach reach (SLING_ATTACH_2D /
    // SLING_ATTACH_HEIGHT), so an out-of-range cargo is never picked. The
    // first pair with a true verdict is the nearest slingloadable cargo. The
    // radius is SLING_SCAN_RADIUS by design: the scope shows what the hook
    // will pick.
    private _candidates = [_vehicle, SLING_SCAN_RADIUS] call FUNC(scanSlingTargets);
    private _cargo = objNull;

    {
        if (_x select 1) then {
            _cargo = _x select 0;
            breakOut "";
        };
    } forEach _candidates;

    if (isNull _cargo) exitWith { [false, "no cargo in range"] };

    // The rope attach flag must be up on both ends for setSlingLoad; remember
    // the cargo's old state so a failed attach changes nothing and a release
    // can restore it.
    private _wasRopeAttach = ropeAttachEnabled _cargo;
    _vehicle enableRopeAttach true;
    _cargo enableRopeAttach true;
    GVAR(slingCargo) = [_cargo, _wasRopeAttach];

    if (_vehicle setSlingLoad _cargo) exitWith {
        [true, netId _cargo]
    };

    GVAR(slingCargo) = nil;
    _cargo enableRopeAttach _wasRopeAttach;
    [false, "sling load failed"]
} else {
    _vehicle setSlingLoad objNull;

    private _last = GVAR(slingCargo);
    GVAR(slingCargo) = nil;
    // isNil takes the variable NAME, not the value: _last holds the pair or
    // nil, and only the nil case skips the rope-attach restore.
    if (!isNil "_last") then {
        // GVAR(slingCargo) is only ever written by this function, so a
        // presence test is the full shape check.
        _last params ["_lastCargo", "_lastWasRopeAttach"];
        if (!isNull _lastCargo) then {
            _lastCargo enableRopeAttach _lastWasRopeAttach;
        };
    };

    [true, ""];
};
