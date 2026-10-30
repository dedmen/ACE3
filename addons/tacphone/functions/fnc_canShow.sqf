#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Tests if the TacPhone can be shown in a mode.
 *
 * Arguments:
 * The display mode to test showing <NUMBER>
 *
 * Return Value:
 * <BOOL>
 *
 * Example:
 * [1] call ace_tacphone_fnc_canShow
 *
 * Public: No
 */

params ["_showType"];

switch (_showType) do {
    case (DISPLAY_MODE_CLOSED): { true }; //Can always close
    case (DISPLAY_MODE_HIDDEN): { true }; //Can always hide
    case (DISPLAY_MODE_DIALOG): {
        ("ACE_Tacphone" in (ACE_player call EFUNC(common,uniqueItems))) &&
        {[ACE_player, objNull, ["notOnMap", "isNotInside", "isNotSitting"]] call EFUNC(common,canInteractWith)}
    };
    case (DISPLAY_MODE_HUD): {
        //Same constraints as the microDAGR HUD
        ((cameraView != "GUNNER") || {(!isNull objectParent ACE_player) && {driver vehicle ACE_player == ACE_player}}) &&
        {"ACE_Tacphone" in (ACE_player call EFUNC(common,uniqueItems))} &&
        {[ACE_player, objNull, ["notOnMap", "isNotInside", "isNotSitting"]] call EFUNC(common,canInteractWith)}
    };
    default { false };
};
