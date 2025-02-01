#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Handle the app being closed
 *
 * Arguments:
 * TacPhone main display
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_messaging_fnc_onClose
 *
 * Public: No
 */

params ["_display"];

// We simply clear out the app section
ctrlDelete GVAR(appsection);