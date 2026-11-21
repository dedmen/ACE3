#include "..\script_component.hpp"
/*
 * Author: Dedmen
 *
 * Arguments:
 * 0: Marker name <STRING>
 *
 * Return Value:
 * ARRAY
 *
 * Example:
 * ["marker_0"] call ace_tacphone_Map_fnc_assembleMarkerInfo
 *
 * Public: No
 */

params ["_marker"];



[
    _marker,
    markerType _marker,
    markerColor _marker,
    markerDir _marker,
    markerPos _marker,
    markerText _marker,
    markerShape _marker,
    markerAlpha _marker,
    markerSize _marker,
    markerChannel _marker,
    markerPolyline _marker joinString ";",
    markerBrush _marker
]

