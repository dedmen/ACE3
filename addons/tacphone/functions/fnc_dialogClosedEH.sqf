#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Handles the TacPhone dialog closing and switches back to HUD mode.
 * Clears the stored dialog display first, so openDisplay will not try to close a display that is already unloading.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call ace_tacphone_fnc_dialogClosedEH
 *
 * Public: No
 */

uiNamespace setVariable [QGVAR(InteractiveDialog), displayNull];
if (GVAR(currentShowMode) != DISPLAY_MODE_DIALOG) exitWith {};
[DISPLAY_MODE_HUD] call FUNC(openDisplay);
