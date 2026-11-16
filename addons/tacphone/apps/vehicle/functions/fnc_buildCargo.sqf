#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the Vehicle.Cargo payload (without a/c) for one vehicle: the ACE
 * cargo inventory as {id, name, size, duration} items plus the free space and
 * total capacity. size is the slot size; duration is the paradrop delay in
 * seconds (the same ace_cargo_fnc_getDelayItem the drop itself uses), so the
 * phone can show how long a drop takes before it starts. Object entries are
 * identified by netId, classname entries by the classname itself;
 * fnc_doAirdrop re-finds the entry by that id on drop, so two equal classnames
 * are interchangeable.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * HASHMAP { items: [ {id, name, size, duration}, ... ], spaceFree, capacity }
 *
 * Example:
 * [vehicle player] call ace_tacphone_vehicle_fnc_buildCargo
 *
 * Public: No
 */

params ["_vehicle"];

// Without the addon there is no inventory; the caller decides whether to send the empty payload
if (!GVAR(hasCargoAddon)) exitWith {
    createHashMapFromArray [["items", []], ["spaceFree", 0], ["capacity", 0]];
};

private _items = [];
{
    _items pushBack createHashMapFromArray [
        // Objects by netId, classnames by themselves
        ["id", if (_x isEqualType objNull) then { netId _x } else { _x }],
        ["name", [_x, true] call ace_cargo_fnc_getNameItem],
        ["size", _x call ace_cargo_fnc_getSizeItem],
        ["duration", [_x, true] call ace_cargo_fnc_getDelayItem]
    ];
} forEach (_vehicle getVariable ["ace_cargo_loaded", []]);

createHashMapFromArray [
    ["items", _items],
    ["spaceFree", _vehicle call ace_cargo_fnc_getCargoSpaceLeft],
    ["capacity", _vehicle getVariable ["ace_cargo_space", getNumber (configOf _vehicle >> "ace_cargo_space")]]
];
