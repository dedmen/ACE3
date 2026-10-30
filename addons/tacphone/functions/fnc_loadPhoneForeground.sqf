#include "..\script_component.hpp"
/*
 * Author: KJW
 * Loads a TacPhone reference, a UI that references our invisible "background" phone, to allow to interact with it
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_fnc_loadPhoneForeground
 *
 * Public: No
 */

createDialog QGVAR(InteractiveDialog);
private _emptyDisplay = uiNamespace getVariable [QGVAR(InteractiveDialog), displayNull];
if (isNull _emptyDisplay) exitWith { ERROR("TacPhone dialog could not be created"); };
private _background = _emptyDisplay ctrlCreate ["RscPicture", -1];

// Lay out the phone body (not the square texture) and derive everything from its width,
// so the background texture keeps its aspect ratio on any screen.
private _bodyWidth = 0.9 * safeZoneW;
private _bodyHeight = _bodyWidth * (safeZoneW / safeZoneH) / TACPHONE_BG_BODY_ASPECT;
if (_bodyHeight > 0.9 * safeZoneH) then {
    _bodyHeight = 0.9 * safeZoneH;
    _bodyWidth = _bodyHeight * TACPHONE_BG_BODY_ASPECT / (safeZoneW / safeZoneH);
};

private _bodyX = safeZoneX + (safeZoneW - _bodyWidth) / 2;
private _bodyY = safeZoneY + (safeZoneH - _bodyHeight) / 2;

// The square background texture has the phone body as a horizontal band in the middle
private _backgroundWidth = _bodyWidth;
private _backgroundHeight = _bodyWidth * (safeZoneW / safeZoneH);

_background ctrlSetPosition [
    _bodyX,
    _bodyY - TACPHONE_BG_BODY_TOP * _backgroundHeight,
    _backgroundWidth,
    _backgroundHeight
];
_background ctrlSetText QPATHTOF(data\tx\phone_bg_ca.paa);//"#(rgb,1,1,1)color(0.3,0.3,0.3,1)";
_background ctrlCommit 0;
_background ctrlAddEventHandler ["Destroy",{
    params ["_control"];

    //private _getAppConfig = {
    //    private _cfg = missionConfigFile >> QGVAR(apps) >> _this;
    //    if (isNull _cfg) then {
    //        _cfg = configFile >> QGVAR(apps) >> _this;
    //    };
    //    _cfg // Might be configNull if no app was actually found
    //};

    //private _appCfg = GVAR(app_selected) call _getAppConfig;
    //private _function = getText (_appCfg >> QGVAR(onClose));
    //private _code = missionNamespace getVariable [_function, ""];
    //if (_code isEqualTo "") exitWith {};
    //[ctrlParent _appsection, _appsection] call _code;
    //#TODO tell the browser to save last things, but we can't really get result back
}];

private _appSection = _emptyDisplay ctrlCreate ["TacPhoneWebBrowserReference", -1];
_appSection ctrlSetPosition [
    _bodyX + 0.015 * _bodyWidth,
    _bodyY + 0.03 * _bodyHeight,
    0.97 * _bodyWidth,
    0.94 * _bodyHeight
];
_appSection ctrlCommit 0;

// Display our background browser on this surface and match the browser resolution to it
[_appSection] call FUNC(linkPhoneControl);

