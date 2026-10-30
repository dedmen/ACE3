#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * "ace_markers_markerPlaced" CBA event handler.
 * Forwards the newly placed marker to FUNC(onMarkerCreated), the second argument (the marker being edited)
 * is irrelevant here because the edit itself raises a marker event.
 *
 * Arguments:
 * 0: Newly placed marker <STRING> (nil when only a marker was edited)
 * 1: Marker being edited <STRING> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["marker_0", ""] call ace_tacphone_map_fnc_onMarkerPlaced
 *
 * Public: No
 */

params ["_newestMarker", "_editingMarker"];

if (isNil "_newestMarker") exitWith {};

_newestMarker call FUNC(onMarkerCreated);
