#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * #TODO
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ARRAY
 *
 * Example:
 * [] call ace_tacphone_map_fnc_assembleMarkerInfo
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
    markerBrush _marker,
    markerSize _marker joinString ",",
    markerChannel _marker,
    markerPolyline _marker joinString ";"
]

