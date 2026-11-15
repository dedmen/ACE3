#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Runs one validated control action on the player's vehicle.
 * The caller (fnc_processBrowserRequest) has already validated driver,
 * vehicle identity, capability and rate limits.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Action <STRING> (Engine, Gear, Light, CollisionLight, AutoHover, Hook, ActiveSensors, WheelsBrake, Airdrop)
 * 2: State <BOOL>
 * 3: Cargo <STRING> (the airdrop item id for Airdrop; accepted for protocol completeness for the rest, the hook always picks the nearest cargo)
 *
 * Return Value:
 * ARRAY [true] on success, [true, cargoId] for Hook and Airdrop, [false, "error"] on failure
 *
 * Example:
 * [vehicle player, "Engine", true, ""] call ace_tacphone_vehicle_fnc_doControl
 *
 * Public: No
 */

params ["_vehicle", "_action", "_state", "_cargo"];

switch (_action) do {
    case "Engine": {
        // Explicit set, not the "engineOn" action (a toggle): the web sends the
        // desired state, and the result must match it regardless of the current one.
        _vehicle engineOn _state;
        [true]
    };
    case "Gear": {
        // Re-read the gear position so a command queued mid-motion is rejected
        private _gearPhase = _vehicle animationSourcePhase "Gear"; // 1 = retracted
        // _state = true means "retract": allowed only when the gear is fully down.
        if (_state && {_gearPhase > 0.05}) exitWith { [false, "gear busy"] };
        // _state = false means "lower": allowed only when the gear is fully up.
        if (!_state && {_gearPhase < 0.95}) exitWith { [false, "gear busy"] };

        if (_state) then {
            _vehicle action ["LandGearUp", _vehicle];
        } else {
            _vehicle action ["LandGear", _vehicle];
        };
        [true]
    };
    case "Light": {
        // Explicit set, not the "LightOn"/"LightOff" actions: the user's
        // helicopter has no such config actions (enumerated live), so the
        // action form is a no-op there. setPilotLight needs a local vehicle,
        // which the player's own vehicle is.
        _vehicle setPilotLight _state;
        [true]
    };
    case "CollisionLight": {
        _vehicle setCollisionLight _state;
        [true]
    };
    case "AutoHover": {
        if (_state) then {
            _vehicle action ["autoHover", _vehicle];
        } else {
            _vehicle action ["autoHoverCancel", _vehicle];
        };
        [true]
    };
    case "Hook": {
        [_vehicle, _state] call FUNC(doSlingLoad)
    };
    case "ActiveSensors": {
        if (_state) then {
            _vehicle action ["ActiveSensorsOn", _vehicle];
        } else {
            _vehicle action ["ActiveSensorsOff", _vehicle];
        };
        [true]
    };
    case "Airdrop": {
        // The gates (aircraft, item, single-drop, flight condition) live in
        // fnc_doAirdrop, the web only hides its buttons
        [_vehicle, _cargo] call FUNC(doAirdrop)
    };
    case "WheelsBrake": {
        // The engine exposes no getter for the wheel-brake state, so the app
        // tracks the commanded state and reports it in the anim payload
        // (the web tile drives from it and can release). The action only
        // exists on wheeled vehicles; refuse the rest instead of a silent
        // no-op reported as success.
        if (!(_vehicle isKindOf "Car")) exitWith { [false, "no wheels brake on this vehicle"] };

        if (_state) then {
            _vehicle action ["WheelsBrakeOn", _vehicle];
        } else {
            _vehicle action ["WheelsBrakeOff", _vehicle];
        };
        GVAR(wheelsBrake) = _state;
        [true]
    };
    default {
        [false, "unsupported"]
    };
};
