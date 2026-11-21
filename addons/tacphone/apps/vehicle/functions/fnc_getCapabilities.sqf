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
 * HASHMAP { class, displayName, picture, seats, isAir, isHelicopter, canGear, hasGear,
 *           canLight, canCollisionLight, canAutoHover, canSlingLoad,
 *           canActiveSensors, canWheelsBrake, hasCargo, has<AnimationSource> flags }
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
// The engine provides the "gear" animation source at runtime on every
// aircraft (it is in neither the config nor the model files), so its
// existence cannot be detected the way the per-source flags below do.
// Gate the readout on the same property as the control tile.
private _hasGear = getNumber (_cfg >> "gearRetracting") == 1;

private _caps = createHashMapFromArray [
    ["class", configName _cfg],
    ["displayName", getText (_cfg >> "displayName")],
    ["picture", getText (_cfg >> "picture")],
    // Total seats: every position of the vehicle, occupied or empty. The
    // engine's own list (fullCrew with includeEmpty) covers turrets and
    // cargo seats alike; the count is occupancy-invariant, so caching it
    // per vehicle like the flags above is safe.
    ["seats", count (fullCrew [_vehicle, "", true])],
    ["isAir", _isAir],
    ["isHelicopter", _isHeli],
    ["canGear", _hasGear],
    ["hasGear", _hasGear],
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
    // "Gear" is engine-provided at runtime (see above): not a config source.
    ["EngineTemp", "hasEngineTemp"],
    ["RotorHFullyDestroyed", "hasRotorDamage"],
    ["TailRotorHFullyDestroyed", "hasTailRotorDamage"],
    ["ActiveSensorsOn", "hasActiveSensors"],
    ["aoa", "hasAoa"]
];

_cache set [_key, _caps];

_caps
