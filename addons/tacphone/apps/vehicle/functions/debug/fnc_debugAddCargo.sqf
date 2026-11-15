#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Debug helper for the live cargo test suite: loads a test crate into the
 * player's vehicle through the cargo addon's own load path (ace_loadCargo),
 * so the ace_cargoAdded/ace_cargoLoaded events fire and the Vehicle.Cargo
 * push follows naturally.
 *
 * Arguments:
 * 0: Class <STRING> (optional, default "B_supplyCrate_F"; "RoadCone_F" is
 *    size 1, the fast 2.5 s drop of the live tests)
 *
 * Return Value:
 * Result <HASHMAP> { ok, class } or { ok: false, error: STRING }
 *
 * Example:
 * ["RoadCone_F"] call ace_tacphone_vehicle_fnc_debugAddCargo
 *
 * Public: No
 */

params [["_class", ""]];

if (_class == "") then {
    _class = "B_supplyCrate_F";
};

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

// The cargo addon's own load path: it validates the item, updates the
// loaded list and fires the inventory events the push listens to.
["ace_loadCargo", [_class, _vehicle]] call CBA_fnc_localEvent;

createHashMapFromArray [["ok", true], ["class", _class]]
