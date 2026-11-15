#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Single CBA interest transition handler for the Vehicle app.
 * Called from the "ace_tacphone_interestActivated" / "ace_tacphone_interestDeactivated" events,
 * idempotent for every interest branch.
 *
 * Arguments:
 * 0: Interest name <STRING>
 * 1: Interest became active <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ACE_TacPhone_Vehicle.anim", true] call ace_tacphone_vehicle_fnc_onInterestChanged
 *
 * Public: No
 */

params [["_interest", ""], ["_active", false]];

// Anim updates: 5 Hz instrument payload plus crew change handlers.
if (_interest == INTEREST_ANIM) exitWith {
    if (_active) then {
        // Already running, nothing to do (duplicate activation must not start twice)
        if (isNil QGVAR(animPFH)) then {
            GVAR(animPFH) = [FUNC(pushAnim), ANIM_UPDATE_INTERVAL, []] call CBA_fnc_addPerFrameHandler;

            // Push the first sample immediately instead of waiting for the first PFH tick
            [] call FUNC(pushAnim);
        };

        // GetInMan/GetOutMan must be added where the unit is local, in practice on the player.
        // This is separate from the per-frame guard above: the player can still be null very
        // early in the mission, and a duplicate activation must not install the handlers twice.
        if (!isNull player && {isNil QGVAR(crewEventHandlers)}) then {
            private _handlers = createHashMap;

            _handlers set ["GetInMan", player addEventHandler ["GetInMan", FUNC(pushCrew)]];
            _handlers set ["GetOutMan", player addEventHandler ["GetOutMan", FUNC(pushCrew)]];

            GVAR(crewEventHandlers) = _handlers;
        };
    } else {
        // Not running, nothing to stop
        if (!isNil QGVAR(animPFH)) then {
            [GVAR(animPFH)] call CBA_fnc_removePerFrameHandler;
            GVAR(animPFH) = nil;
        };

        // The passenger crew-poll cache belongs to the anim stream; a stale
        // signature would suppress the first push on the next activation.
        GVAR(nextCrewPoll) = nil;
        GVAR(crewSignature) = nil;

        if (!isNil QGVAR(crewEventHandlers)) then {
            // The handlers live on the player object; between respawns there can be none left to clean.
            if (!isNull player) then {
                {
                    player removeEventHandler [_x, _y];
                } forEach GVAR(crewEventHandlers);
            };

            GVAR(crewEventHandlers) = nil;
        };
    };
};

// State updates: 20 Hz attitude payload.
if (_interest == INTEREST_STATE) exitWith {
    if (_active) then {
        // Already running, nothing to do (duplicate activation must not start twice)
        if (isNil QGVAR(statePFH)) then {
            GVAR(statePFH) = [FUNC(pushState), STATE_UPDATE_INTERVAL, []] call CBA_fnc_addPerFrameHandler;

            // Push the first sample immediately instead of waiting for the first PFH tick
            [] call FUNC(pushState);
        };
    } else {
        // Not running, nothing to stop
        if (!isNil QGVAR(statePFH)) then {
            [GVAR(statePFH)] call CBA_fnc_removePerFrameHandler;
            GVAR(statePFH) = nil;
        };
    };
};

// Cargo updates: event-driven one-off Vehicle.Cargo pushes, the inventory
// only changes when cargo changes.
if (_interest == INTEREST_CARGO) exitWith {
    if (_active) then {
        // Already running, nothing to do (duplicate activation must not start twice)
        if (isNil QGVAR(cargoEventHandlers)) then {
            // The events fire globally for every cargo vehicle, even when the
            // player is on foot; push only for the player's own vehicle
            private _handler = {
                if ((_this select 1) isEqualTo vehicle player) then {
                    [] call FUNC(pushCargo);
                };
            };

            private _handlers = createHashMap;
            _handlers set ["ace_cargoAdded", ["ace_cargoAdded", _handler] call CBA_fnc_addEventHandler];
            _handlers set ["ace_cargoLoaded", ["ace_cargoLoaded", _handler] call CBA_fnc_addEventHandler];
            _handlers set ["ace_cargoUnloaded", ["ace_cargoUnloaded", _handler] call CBA_fnc_addEventHandler];
            _handlers set ["ace_cargoRemoved", ["ace_cargoRemoved", _handler] call CBA_fnc_addEventHandler];

            GVAR(cargoEventHandlers) = _handlers;

            // Push the current inventory immediately instead of waiting for the next change
            [] call FUNC(pushCargo);
        };
    } else {
        // Not running, nothing to stop
        if (!isNil QGVAR(cargoEventHandlers)) then {
            {
                [_x select 0, _x select 1] call CBA_fnc_removeEventHandler;
            } forEach GVAR(cargoEventHandlers);

            GVAR(cargoEventHandlers) = nil;
        };
    };
};
