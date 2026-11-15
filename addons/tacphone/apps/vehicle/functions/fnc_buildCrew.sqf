#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the crew list for the local player's vehicle, used by GetVehicle,
 * the anim/state payloads and the one-off crew pushes.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * Array of HASHMAP { name, role, cargoIndex, isPlayer }
 *
 * Example:
 * [vehicle player] call ace_tacphone_vehicle_fnc_buildCrew
 *
 * Public: No
 */

params ["_vehicle"];

// Each fullCrew entry is [unit, role, cargoIndex, ...]; the driver seat
// carries cargoIndex -1, so the role string fullCrew already provides is
// the only source that covers every seat, driver included.
(fullCrew _vehicle) apply {
    // Inside apply the entry is _x; a bare params would read _this (the whole list)
    _x params ["_unit", "_role", "_cargoIndex"];

    createHashMapFromArray [
        ["name", name _unit],
        ["role", _role],
        ["cargoIndex", _cargoIndex],
        ["isPlayer", _unit == player]
    ]
};
