#include "script_component.hpp"

// Anim and state streams are demand driven: they only run while a client holds the matching interest.
// See FUNC(onInterestChanged).
["ace_tacphone_interestActivated", {
    [_this select 0, true] call FUNC(onInterestChanged);
}] call CBA_fnc_addEventHandler;
["ace_tacphone_interestDeactivated", {
    [_this select 0, false] call FUNC(onInterestChanged);
}] call CBA_fnc_addEventHandler;

// Crew and vehicle changes are one-off pushes, they do not depend on an interest.
// Raw GetInMan/GetOutMan unit handlers on the player: the engine fires them
// with [unit, role, vehicle, turret(, isEject)] for moveIn/moveOut, the
// GetInXXXX/GetOut actions and key presses. CBA_fnc_addPlayerEventHandler
// does not know these events (it returns -1). A respawn replaces the unit
// object, so the handlers die with the old unit; FUNC(onPlayerRespawned)
// reinstalls them on the new player.
// Client-only: on a dedicated server / headless client `player` is objNull
// (and unguarded, addEventHandler would error), so both predicates guard the
// install; hasInterface covers the headless-with-interface edge.
if (!isNull player && {hasInterface}) then {
    player addEventHandler ["GetInMan", FUNC(onVehicleChanged)];
    player addEventHandler ["GetOutMan", FUNC(onVehicleChanged)];
    player addEventHandler ["SeatSwitchedMan", FUNC(onSeatSwitched)];
};

addMissionEventHandler ["EntityRespawned", FUNC(onPlayerRespawned)];
