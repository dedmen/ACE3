#include "script_component.hpp"

//#include "initKeybinds.inc.sqf"



addMissionEventHandler ["MarkerCreated", FUNC(onMarkerCreated)];
addMissionEventHandler ["MarkerUpdated", FUNC(onMarkerPosChanged)];
addMissionEventHandler ["MarkerDeleted", FUNC(onMarkerDeleted)];

["ace_markers_setMarkerPosLocal", FUNC(onMarkerPosChanged)] call CBA_fnc_addEventHandler;
["ace_markers_markerPlaced", {
    params ["_newestMarker", "_editingMarker"];

    _this call FUNC(onMarkerCreated);
}] call CBA_fnc_addEventHandler;
