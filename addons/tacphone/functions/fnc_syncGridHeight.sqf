#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * The HUD keeps the background texture's aspect ratio by deriving the phone body height from the
 * configured width. The layout editor uses the stored height for its preview, so keep that value
 * in sync with the height the HUD actually draws.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_fnc_syncGridHeight
 *
 * Public: No
 */

private _width = profileNamespace getVariable ["IGUI_grid_ACE_tacPhone_W", TACPHONE_DEFAULT_W];
private _height = _width * (safeZoneW / safeZoneH) * TACPHONE_BG_BODY_HEIGHT;

// The layout editor reads uinamespace first and falls back to the profile
uiNamespace setVariable ["IGUI_grid_ACE_tacPhone_H", _height];
profileNamespace setVariable ["IGUI_grid_ACE_tacPhone_H", _height];
