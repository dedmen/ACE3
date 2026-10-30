#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Registers the marker event handlers once the first client starts to care about marker updates.
 * Called from the "ace_tacphone_interestActivated" CBA event, idempotent.
 *
 * Arguments:
 * 0: Interest name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ACE_TacPhone_Map.markers"] call ace_tacphone_map_fnc_onInterestActivated
 *
 * Public: No
 */

params ["_interest"];

if (_interest != INTEREST_MARKERS) exitWith {};

// Already installed, nothing to do (duplicate activation must not register twice)
if (!isNil QGVAR(markerEventsActive) && {GVAR(markerEventsActive)}) exitWith {};

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
