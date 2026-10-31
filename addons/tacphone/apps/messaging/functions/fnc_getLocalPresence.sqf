#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Presence of the local player, derived from the TacPhone display mode.
 *
 * The phone is "available" while it is shown as HUD or dialog and "minimized"
 * while it is closed or hidden. A connected phone never counts as offline.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Presence <STRING> ("available" or "minimized")
 *
 * Example:
 * [] call ace_tacphone_Messaging_fnc_getLocalPresence
 *
 * Public: No
 */

private _mode = EGVAR(tacphone,currentShowMode);

if (!isNil "_mode" && {_mode in [MESSAGING_DISPLAY_MODE_HUD, MESSAGING_DISPLAY_MODE_DIALOG]}) exitWith {
    MESSAGING_PRESENCE_AVAILABLE
};

MESSAGING_PRESENCE_MINIMIZED
