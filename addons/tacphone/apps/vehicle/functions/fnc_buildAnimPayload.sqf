#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the 5 Hz instrument payload (plan 4.2) for a vehicle.
 * Animation sources that do not exist on this vehicle are omitted entirely;
 * the web side treats missing fields as null and hides the instrument. The
 * exception is the altitude readout: AltBaro/AltRadar are engine-provided
 * at runtime (not in the vehicle config) and are always read.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * HASHMAP of the Vehicle.Anim fields (without a/c)
 *
 * Example:
 * [vehicle player] call ace_tacphone_vehicle_fnc_buildAnimPayload
 *
 * Public: No
 */

params ["_vehicle"];

// Cached per vehicle; also tells us which animation sources exist.
private _caps = [_vehicle] call FUNC(getCapabilities);

private _payload = createHashMap;

if (_caps get "hasRpm") then {
    _payload set ["rpm", _vehicle animationSourcePhase "Rpm"];
};
if (_caps get "hasSpeed") then {
    _payload set ["speed", _vehicle animationSourcePhase "Speed"];
};
// Engine-provided at runtime, not in the vehicle config: always read, the
// way TacControl does. See fnc_buildStatePayload for the detail.
_payload set ["altBaro", _vehicle animationSourcePhase "AltBaro"];
_payload set ["altRadar", _vehicle animationSourcePhase "AltRadar"];
if (_caps get "hasVertSpeed") then {
    _payload set ["vertSpeed", _vehicle animationSourcePhase "VertSpeed"];
};
if (_caps get "hasGear") then {
    _payload set ["gear", _vehicle animationSourcePhase "Gear"]; // 1 = retracted
};
if (_caps get "hasEngineTemp") then {
    _payload set ["engineTemp", _vehicle animationSourcePhase "EngineTemp"];
};
if (_caps get "hasRotorDamage") then {
    _payload set ["rotorDamage", _vehicle animationSourcePhase "RotorHFullyDestroyed" > 0.5];
};
if (_caps get "hasTailRotorDamage") then {
    _payload set ["tailRotorDamage", _vehicle animationSourcePhase "TailRotorHFullyDestroyed" > 0.5];
};
if (_caps get "hasActiveSensors") then {
    _payload set ["activeSensors", _vehicle animationSourcePhase "ActiveSensorsOn" > 0.5];
};

// isAutoHoverOn is meaningless on non-helicopters, omit it there
if (_caps get "isHelicopter") then {
    _payload set ["autoHover", isAutoHoverOn _vehicle];
};

// Always available, not gated on animation sources: the eco-mode HUD renders
// heading, speed, the GND/HOVER badge and the horizon from these (the visual
// vectors are the attitude source in both update-rate modes).
_payload set ["dir", getDirVisual _vehicle];
_payload set ["velocityMS", velocityModelSpace _vehicle];
_payload set ["velocity", velocity _vehicle];
_payload set ["vectorDir", vectorDirVisual _vehicle];
_payload set ["vectorUp", vectorUpVisual _vehicle];
_payload set ["onGround", isTouchingGround _vehicle];

_payload set ["wheelsBrake", GVAR(wheelsBrake)];
_payload set ["fuel", fuel _vehicle];
_payload set ["engineOn", isEngineOn _vehicle];
_payload set ["lightOn", isLightOn _vehicle];
_payload set ["collisionLight", isCollisionLightOn _vehicle];

private _slingLoad = getSlingLoad _vehicle;
_payload set ["slingLoaded", if (isNull _slingLoad) then { "" } else { netId _slingLoad }];

// No crew here: crew only changes on board/dismount, and the 0.5 Hz
// signature-gated poll in fnc_pushAnim (plus the one-off Vehicle.Crew
// pushes) is the sole crew source for driver and passengers alike.

// Airdrop readiness, only for cargo vehicles: the phone and the in-game
// progress bar must agree, so these are the same expressions as fnc_doAirdrop's
// condition block (tilt, height; deliberately no speed/reverse gate).
if (_caps get "hasCargo") then {
    if (_caps get "isAir") then {
        private _unlevel = (acos ((vectorUp _vehicle) select 2)) > 30;
        private _low = ((getPos _vehicle) select 2) < 25;

        _payload set ["canAirdrop", !(_unlevel || {_low})];
        // Only when disabled, so the web can show a hint; priority follows the
        // doAirdrop re-check order
        if (!(_payload get "canAirdrop")) then {
            _payload set ["airdropReason", if (_unlevel) then { "unlevel" } else { "low" }];
        };
    } else {
        // Ground vehicles are read-only: no airdrop, and no reason (the web
        // hides the button there and needs no hint)
        _payload set ["canAirdrop", false];
    };
};

_payload
