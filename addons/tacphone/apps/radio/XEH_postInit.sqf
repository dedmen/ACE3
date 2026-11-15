#include "script_component.hpp"

// Radio handlers are demand driven: the TFAR event handlers only exist while a
// client holds INTEREST_RADIOS. See FUNC(onInterestChanged).
["ace_tacphone_interestActivated", {
    [_this select 0, true] call FUNC(onInterestChanged);
}] call CBA_fnc_addEventHandler;
["ace_tacphone_interestDeactivated", {
    [_this select 0, false] call FUNC(onInterestChanged);
}] call CBA_fnc_addEventHandler;

// Safety paths that end a transmission regardless of the page state. EntityKilled
// and EntityRespawned are mission events (v1.56): they fire for every unit, so
// the handlers filter on `_unit == player`. The vehicle events must attach to
// the player object itself; the player can still be null very early in the
// mission, so that install is deferred until the player object exists.
addMissionEventHandler ["EntityKilled", FUNC(onPlayerKilled)];
addMissionEventHandler ["EntityRespawned", FUNC(onPlayerRespawned)];

[
    // Condition: the player object must exist before it can carry handlers
    { !isNull player },
    // Statement: attach the vehicle-change stop paths to the player object
    {
        player addEventHandler ["GetInMan", FUNC(onVehicleChanged)];
        player addEventHandler ["GetOutMan", FUNC(onVehicleChanged)];
    }
] call CBA_fnc_waitUntilAndExecute;

// Mission end: force-end any active transmission, nothing may outlive the mission.
addMissionEventHandler ["Ended", FUNC(onEnded)];
