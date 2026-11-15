#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Capability detection table for a vehicle. Results are cached per vehicle
 * netId in GVAR(capabilityCache); fnc_onVehicleChanged clears the cache.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * HASHMAP { class, displayName, picture, isAir, isHelicopter, canGear, canLight,
 *           canCollisionLight, canAutoHover, canSlingLoad, canActiveSensors,
 *           canWheelsBrake, hasCargo, has<AnimationSource> flags }
 *
 * Example:
 * [vehicle player] call ace_tacphone_vehicle_fnc_getCapabilities
 *
 * Public: No
 */

params ["_vehicle"];

if (isNil QGVAR(capabilityCache)) then {
    GVAR(capabilityCache) = createHashMap;
};

private _cache = GVAR(capabilityCache);
private _key = netId _vehicle;

// Already cached for this vehicle
if (_key in _cache) exitWith { _cache get _key };

private _cfg = configOf _vehicle;
private _isAir = _vehicle isKindOf "Air";
private _isHeli = _vehicle isKindOf "Helicopter";

private _caps = createHashMapFromArray [
    ["class", configName _cfg],
    ["displayName", getText (_cfg >> "displayName")],
    ["picture", getText (_cfg >> "picture")],
    ["isAir", _isAir],
    ["isHelicopter", _isHeli],
    ["canGear", getNumber (_cfg >> "gearRetracting") == 1],
    ["canLight", true], // Plan default for ground and air
    ["canCollisionLight", _isAir],
    ["canAutoHover", _isHeli],
    ["canSlingLoad", _isHeli || {isText (_cfg >> "slingLoadMemoryPoint")}],
    ["canActiveSensors", isClass (_cfg >> "AnimationSources" >> "ActiveSensorsOn")],
    // Only wheeled ground vehicles carry the WheelsBrakeOn/Off actions; boats
    // (Ship) and tracked vehicles (Tank) would silently no-op them.
    ["canWheelsBrake", _vehicle isKindOf "Car"],
    // ACE cargo is optional; the same condition cargo itself uses for its
    // vehicle action, plus the runtime addon check
    ["hasCargo", GVAR(hasCargoAddon) && {_vehicle getVariable ["ace_cargo_hasCargo", getNumber (_cfg >> "ace_cargo_hasCargo") == 1]}]
];

// Per animation source existence flags; the payload builders skip missing sources.
{
    _caps set [_x select 1, isClass (_cfg >> "AnimationSources" >> (_x select 0))];
} forEach [
    ["Rpm", "hasRpm"],
    ["Speed", "hasSpeed"],
    ["VertSpeed", "hasVertSpeed"],
    ["HorizonBank", "hasHorizonBank"],
    ["HorizonDive", "hasHorizonDive"],
    ["Gear", "hasGear"],
    ["EngineTemp", "hasEngineTemp"],
    ["RotorHFullyDestroyed", "hasRotorDamage"],
    ["TailRotorHFullyDestroyed", "hasTailRotorDamage"],
    ["ActiveSensorsOn", "hasActiveSensors"],
    ["aoa", "hasAoa"]
];

_cache set [_key, _caps];

_caps
