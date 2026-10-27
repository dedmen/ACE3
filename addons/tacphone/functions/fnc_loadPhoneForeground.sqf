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

private _emptyDisplay = createDialog ["RscDisplayEmpty", true];
private _background = _emptyDisplay ctrlCreate ["RscPicture", -1];

private _phoneWidth = PHONE_WIDTH+0.1;
private _phoneHeight = PHONE_HEIGHT+0.1;
_background ctrlSetPosition [(1-_phoneWidth)/2, (1-_phoneWidth-0.23)/2, _phoneWidth, _phoneWidth+0.25];//[(1-_phoneWidth)/2, (1-_phoneHeight)/2, _phoneWidth, _phoneHeight];
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
_appSection ctrlSetPosition [(1-PHONE_WIDTH-0.0675)/2, (1-PHONE_HEIGHT)/2, PHONE_WIDTH+0.0675, PHONE_HEIGHT];
_appSection ctrlCommit 0;

// Display our background browser, on this surface
_appSection ctrlWebBrowserAction ["SetControlReference", uiNamespace getVariable QGVAR(appSection)];
 // Match the browser resolution to what we'll display here
(uiNamespace getVariable QGVAR(appSection)) ctrlWebBrowserAction ["SetBrowserInternalSize", PHONE_WIDTH+0.0675, PHONE_HEIGHT];

