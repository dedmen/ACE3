#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Single CBA interest transition handler for the Map app.
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
 * ["ACE_TacPhone_Map.markers", true] call ace_tacphone_map_fnc_onInterestChanged
 *
 * Public: No
 */

params [["_interest", ""], ["_active", false]];

// Marker updates: install/remove exactly the marker event handlers.
if (_interest == INTEREST_MARKERS) exitWith {
    if (_active) then {
        // Already installed, nothing to do (duplicate activation must not register twice)
        if (isNil QGVAR(markerEventsActive) || {!GVAR(markerEventsActive)}) then {
            private _handlers = createHashMap;

            // mission event handlers, keyed by event name
            _handlers set ["MarkerCreated", addMissionEventHandler ["MarkerCreated", FUNC(onMarkerCreated)]];
            _handlers set ["MarkerUpdated", addMissionEventHandler ["MarkerUpdated", FUNC(onMarkerPosChanged)]];
            _handlers set ["MarkerDeleted", addMissionEventHandler ["MarkerDeleted", FUNC(onMarkerDeleted)]];

            // ACE marker event handlers, keyed by event name
            _handlers set ["ace_markers_setMarkerPosLocal", ["ace_markers_setMarkerPosLocal", FUNC(onMarkerPosChanged)] call CBA_fnc_addEventHandler];
            _handlers set ["ace_markers_markerPlaced", ["ace_markers_markerPlaced", FUNC(onMarkerPlaced)] call CBA_fnc_addEventHandler];

            GVAR(markerEventHandlers) = _handlers;
            GVAR(markerEventsActive) = true;
        };
    } else {
        // Not installed, nothing to remove
        if (!isNil QGVAR(markerEventsActive) && {GVAR(markerEventsActive)}) then {
            private _handlers = GVAR(markerEventHandlers);

            {
                private _id = _handlers get _x;

                if (!isNil "_id") then {
                    removeMissionEventHandler [_x, _id];
                };
            } forEach ["MarkerCreated", "MarkerUpdated", "MarkerDeleted"];

            {
                private _id = _handlers get _x;

                if (!isNil "_id") then {
                    [_x, _id] call CBA_fnc_removeEventHandler;
                };
            } forEach ["ace_markers_setMarkerPosLocal", "ace_markers_markerPlaced"];

            GVAR(markerEventHandlers) = createHashMap;
            GVAR(markerEventsActive) = false;
        };
    };
};

// GPS updates: per-frame position push plus unit vehicle-change handlers.
if (_interest == INTEREST_GPS) exitWith {
    if (_active) then {
        // Already running, nothing to do (duplicate activation must not start twice)
        if (isNil QGVAR(gpsPFH)) then {
            GVAR(gpsPFH) = [FUNC(onGpsUpdate), GPS_UPDATE_INTERVAL, []] call CBA_fnc_addPerFrameHandler;

            // Give the GPS a fix immediately instead of waiting for the first PFH tick
            [] call FUNC(onGpsUpdate);
        };

        // GetInMan/GetOutMan must be added where the unit is local, in practice on the player.
        // This is separate from the per-frame guard above: the player can still be null very
        // early in the mission, and a duplicate activation must not install the handlers twice.
        if (!isNull player && {isNil QGVAR(gpsVehicleEventHandlers)}) then {
            private _handlers = createHashMap;

            _handlers set ["GetInMan", player addEventHandler ["GetInMan", FUNC(onGpsVehicleChanged)]];
            _handlers set ["GetOutMan", player addEventHandler ["GetOutMan", FUNC(onGpsVehicleChanged)]];

            GVAR(gpsVehicleEventHandlers) = _handlers;
        };
    } else {
        // Not running, nothing to stop
        if (!isNil QGVAR(gpsPFH)) then {
            [GVAR(gpsPFH)] call CBA_fnc_removePerFrameHandler;
            GVAR(gpsPFH) = nil;
        };

        if (!isNil QGVAR(gpsVehicleEventHandlers)) then {
            // The handlers live on the player object; between respawns there can be none left to clean.
            if (!isNull player) then {
                {
                    player removeEventHandler [_x, _y];
                } forEach GVAR(gpsVehicleEventHandlers);
            };

            GVAR(gpsVehicleEventHandlers) = nil;
        };
    };
};
