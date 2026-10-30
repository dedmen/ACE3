#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Removes the marker event handlers again once the last client stops caring about marker updates.
 * Called from the "ace_tacphone_interestDeactivated" CBA event, idempotent.
 *
 * Arguments:
 * 0: Interest name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ACE_TacPhone_Map.markers"] call ace_tacphone_map_fnc_onInterestDeactivated
 *
 * Public: No
 */

params ["_interest"];

if (_interest != INTEREST_MARKERS) exitWith {};
if (isNil QGVAR(markerEventsActive) || {!GVAR(markerEventsActive)}) exitWith {};

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
