#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Debug helper for the live sling scope test suite: spawns a test cargo below
 * the player's helicopter (the Z offset puts it clearly under), so the
 * Vehicle.Sling stream and the Hook pick can be exercised without real cargo.
 * Repeated calls delete the previous test cargo first, UNLESS `keep` is set:
 * a keep call appends the probe object alongside the current scene cargo (the
 * suite uses this for objects that must coexist with the scene cargo, such as
 * the beyond-range crate and the animal-exclusion snake).
 *
 * The default is a quad bike: the standard cargo crate
 * (B_Slingload_01_Cargo_F) fails the Exile's canSlingLoad in the test
 * mission, while the quad is verified sling-loadable and light enough for
 * any sling-capable heli. The default offset is WITHIN the pilot-hook reach
 * (SLING_ATTACH_2D / SLING_ATTACH_HEIGHT) for a heli in the air, so a fresh
 * scene is hookable as spawned.
 *
 * Arguments:
 * 0: Class <STRING> (default "B_Quadbike_01_F")
 * 1: Offset <ARRAY> (3-vector relative to the helicopter, default [0, -3, -15])
 * 2: Keep <BOOL> (default false; do not clear the previous scene cargo,
 *    append this object to it)
 * 3: Clear <BOOL> (default false; delete ALL scene cargo and spawn nothing)
 *
 * Return Value:
 * Result <HASHMAP> { ok, class, cargo (netId) }, { ok, cleared } for a clear,
 * or { ok: false, error: STRING }
 *
 * Example:
 * ["B_Quadbike_01_F", [0, -3, -15]] call ace_tacphone_vehicle_fnc_debugSlingScene
 *
 * Public: No
 */

params [["_class", "B_Quadbike_01_F"], ["_offset", [0, -3, -15]], ["_keep", false], ["_clear", false]];

if (isNull player) exitWith {
    createHashMapFromArray [["ok", false], ["error", "no player"]];
};

private _vehicle = vehicle player;
if (_vehicle isEqualTo player) exitWith {
    createHashMapFromArray [["ok", false], ["error", "not in vehicle"]];
};
// Driver gate like Debug.ApplyFlight
if (driver _vehicle isNotEqualTo player) exitWith {
    createHashMapFromArray [["ok", false], ["error", "not driver"]];
};

// Clear mode: delete all scene cargo (test cleanup) and spawn nothing.
if (_clear) exitWith {
    if (!isNil QGVAR(debugSlingScene)) then {
        {
            if (!isNull _x && {alive _x}) then {
                deleteVehicle _x;
            };
        } forEach GVAR(debugSlingScene);
        GVAR(debugSlingScene) = [];
    };
    createHashMapFromArray [["ok", true], ["cleared", true]];
};

// Remove the test cargo from the previous run. A keep call appends instead
// of clearing: the probe objects live alongside the scene cargo until the
// next non-keep call.
if (!_keep) then {
    if (!isNil QGVAR(debugSlingScene)) then {
        {
            if (!isNull _x && {alive _x}) then {
                deleteVehicle _x;
            };
        } forEach GVAR(debugSlingScene);
        GVAR(debugSlingScene) = [];
    };
};
if (isNil QGVAR(debugSlingScene)) then {
    GVAR(debugSlingScene) = [];
};

// Spawn at the helicopter, then place at the offset: getPosATL keeps the
// position in the same frame the scope and the scan work in, and the Z
// offset (default -15) puts the cargo clearly below the helicopter centre.
private _heliPos = getPosATL _vehicle;
private _cargo = createVehicle [_class, _heliPos];
_cargo setPosATL [
    (_heliPos select 0) + (_offset select 0),
    (_heliPos select 1) + (_offset select 1),
    (_heliPos select 2) + (_offset select 2)
];

GVAR(debugSlingScene) pushBack _cargo;

createHashMapFromArray [
    ["ok", true],
    ["class", _class],
    ["cargo", netId _cargo]
]
