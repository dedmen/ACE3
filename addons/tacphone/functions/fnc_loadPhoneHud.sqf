#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Shows the non-interactive TacPhone HUD (RscTitles element positioned by CfgUIGrids).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_fnc_loadPhoneHud
 *
 * Public: No
 */
private _layer = QGVAR(HUDDisplay) call BIS_fnc_rscLayer;
_layer cutRsc [QGVAR(HUDDisplay), "PLAIN", 0, true];

//The display may not exist until the next frame; link the browser reference then.
[{
    if (GVAR(currentShowMode) != DISPLAY_MODE_HUD) exitWith {};
    private _display = uiNamespace getVariable [QGVAR(HUDDisplay), displayNull];
    if (isNull _display) exitWith {};
    [_display displayCtrl IDC_TACPHONE_APP] call FUNC(linkPhoneControl);
}, []] call CBA_fnc_execNextFrame;
