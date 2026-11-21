#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the 20 Hz attitude payload (plan 4.3) for a vehicle.
 * Animation sources that do not exist on this vehicle are omitted entirely;
 * the web side treats missing fields as null. The exception is the altitude
 * readout: AltBaro/AltRadar are engine-provided at runtime (not in the
 * vehicle config) and are always read.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * HASHMAP of the Vehicle.State fields including the CBA_missionTime sample
 * timestamp t (without a/c)
 *
 * Example:
 * [vehicle player] call ace_tacphone_vehicle_fnc_buildStatePayload
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
// Barometric and radar altitude: the engine provides the AltBaro/AltRadar
// animation sources at runtime (they are not part of the vehicle config, so
// a config probe can never see them). Read them unconditionally, the way
// TacControl does; the value is in metres and sits near 0 on the ground.
_payload set ["altBaro", _vehicle animationSourcePhase "AltBaro"];
_payload set ["altRadar", _vehicle animationSourcePhase "AltRadar"];
if (_caps get "hasAoa") then {
    _payload set ["aoa", _vehicle animationSourcePhase "aoa"];
};
if (_caps get "hasSpeed") then {
    _payload set ["speed", _vehicle animationSourcePhase "Speed"];
};
if (_caps get "hasVertSpeed") then {
    _payload set ["vertSpeed", _vehicle animationSourcePhase "VertSpeed"];
};
_payload set ["velocityMS", velocityModelSpace _vehicle];
// World-space primitives the web derives attitude and flight data from:
// pitch/roll from vectorDir/vectorUp, G and AOA from velocity.
_payload set ["velocity", velocity _vehicle];
_payload set ["vectorDir", vectorDirVisual _vehicle];
_payload set ["vectorUp", vectorUpVisual _vehicle];
_payload set ["dir", getDirVisual _vehicle];
_payload set ["posATL", getPosATL _vehicle];
_payload set ["onGround", isTouchingGround _vehicle];
_payload set ["t", CBA_missionTime];

_payload
