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

private _phoneWidth = PHONE_WIDTH+0.1*2; //#TODO all the *2's/*1.9's here are because I doubled the phone size, but then the background image size got all messed up
private _phoneHeight = PHONE_HEIGHT+0.1*2;
_background ctrlSetPosition [(1-_phoneWidth)/2, (1-_phoneWidth-0.24*2)/2, _phoneWidth, _phoneWidth+0.26*2];//[(1-_phoneWidth)/2, (1-_phoneHeight)/2, _phoneWidth, _phoneHeight];
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
_appSection ctrlSetPosition [(1-PHONE_WIDTH-0.0675*2)/2, (1-PHONE_HEIGHT)/2, PHONE_WIDTH+0.0675*2, PHONE_HEIGHT];
_appSection ctrlCommit 0;

// Display our background browser on this surface and match the browser resolution to it
[_appSection] call FUNC(linkPhoneControl);

