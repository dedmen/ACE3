#include "..\script_component.hpp"
/*
 * Author: KJW
 * Initializes the App
 *
 * Arguments:
 * TacPhone main display
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_messaging_fnc_createApp
 *
 * Public: No
 */

params ["_display", "_appSection"];

private _fullSize = [0, 0, (ctrlPosition _appSection)#2, (ctrlPosition _appSection)#3];

GVAR(appsection) = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1, _appSection];
GVAR(appsection) ctrlSetPosition _fullSize;
GVAR(appsection) ctrlCommit 0;

//#TODO we need to store that variable
private _browserCtrl = _display ctrlCreate [QGVAR(ui), -1, GVAR(appsection)];
_browserCtrl ctrlSetPosition _fullSize;
_browserCtrl ctrlCommit 0;

localNamespace setVariable [QGVAR(browserCtrl), _browserCtrl];

// For development, we want to preprocess the input file, which browser doesn't do by default 

private _indexContent = preprocessFile "z\ace\addons\tacphone\apps\messaging\data\index.html"; //#TODO QPATHTOF

// This is a fix to bypass a bug in ArmaDebugEngine, it inserts #line directive anyway
if (_indexContent select [0,5] == "#line") then {
_indexContent = _indexContent select [_indexContent find (toString [10])];
};

_browserCtrl ctrlWebBrowserAction ["OpenDevConsole"]; //#TODO remove or hide behind #ifdef
_browserCtrl ctrlWebBrowserAction ["OpenDataAsURL", _indexContent];

_browserCtrl ctrlAddEventHandler  ["JSDialog", {
	params ["_control", "_isConfirmDialog", "_message"];
	[_control, _message] call FUNC(handleAppMessage);
	true; // We need to tell it that we handled the "dialog", by returning true or false.
}];

ctrlSetFocus _browserCtrl; // So that scrolling immediately works

//#TODO