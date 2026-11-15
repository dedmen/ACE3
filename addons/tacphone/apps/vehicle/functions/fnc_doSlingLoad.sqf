#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Attaches or releases the sling-load hook. Attach picks the nearest cargo
 * within 40 m that can be sling loaded; release detaches any cargo.
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
    // AllVehicles covers cars/boats/other helis; ThingX covers crates and
    // other props. canSlingLoad does the real compatibility/alive check.
    private _candidates = nearestObjects [_vehicle, ["AllVehicles", "ThingX"], 40];
    private _cargo = objNull;

    {
        if (_x == _vehicle) then { continueWith {}; };
        if (!alive _x) then { continueWith {}; };
        if (!isNull (getSlingLoad _x)) then { continueWith {}; }; // already sling loaded
        if !(_vehicle canSlingLoad _x) then { continueWith {}; };

        _cargo = _x;
        breakOut ""; // nearestObjects is ordered by proximity
    } forEach _candidates;

    if (isNull _cargo) exitWith { [false, "no cargo in range"] };

    // Only the cargo's flag matters for setSlingLoad; remember it so a failed
    // attach changes nothing and a release can restore it.
    private _wasRopeAttach = ropeAttachEnabled _cargo;
    _cargo enableRopeAttach true;
    private _attached = _vehicle setSlingLoad _cargo;

    if (!_attached) exitWith {
        _cargo enableRopeAttach _wasRopeAttach;
        [false, "sling load failed"]
    };

    GVAR(slingCargo) = [_cargo, _wasRopeAttach];
    [true, netId _cargo];
} else {
    _vehicle setSlingLoad objNull;

    private _last = GVAR(slingCargo);
    GVAR(slingCargo) = nil;
    if (!isNil _last) then {
        // GVAR(slingCargo) is only ever written by this function, so a
        // presence test is the full shape check.
        _last params ["_lastCargo", "_lastWasRopeAttach"];
        if (!isNull _lastCargo) then {
            _lastCargo enableRopeAttach _lastWasRopeAttach;
        };
    };

    [true, ""];
};
