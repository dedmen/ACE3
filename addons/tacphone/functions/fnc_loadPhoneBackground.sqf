#include "..\script_component.hpp"
/*
 * Author: KJW
 * Loads tacphone
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_fnc_loadPhoneBackground
 *
 * Public: No
 */


(QGVAR(BackgroundBrowser) call BIS_fnc_rscLayer) cutRsc [QGVAR(BackgroundBrowser), "PLAIN", -1, true, false];

private _backgroundDisplay = uiNamespace getVariable QGVAR(backgroundPhoneDisplay);

private _appSection = _backgroundDisplay displayCtrl 1337;
uiNamespace setVariable [QGVAR(appSection),_appSection];

// This is the core communication channel with the browser, every request comes through here
// It is sent by ACE_TacPhone_Main/src/Backend/Networking.ts Request() method
_appSection ctrlAddEventHandler ["JSDialog", {
    params ["_control", "_isConfirmDialog", "_message"];

    private _request = fromJSON _message;

    if (isNil "_request") exitWith {
        diag_log ["Failed to parse JSON message", _message];
    };

    diag_log ["JSDialog from ingame", _request];
    // Process the request
    // { k: "keystring", d: {...} }
    private _data = _request get "d";
    diag_log ["JSDialog from ingame", _data];
    // _data is { "a": "AppName", "c": "CommandName", ... }
    private _appTarget = _data get "a";

    if !(_appTarget in GVAR(AppInfo)) then {
        diag_log ["Unknown App via command from ingame browser to", _appTarget];
    };

    private _appInfo = GVAR(AppInfo) getOrDefaultCall [_appTarget, {createHashMap}]; //#TODO log error if not found
    private _processor = _appInfo getOrDefaultCall ["requestprocessor", {"UNKNOWN HANDLER in request process"}]; //#TODO log error if not found

    private _result = _data call _processor; // Forward to that app's specific processor

    if (_result isEqualType scriptNull) exitWith {
        // The script sent a promise as result, we don't yet have the data to send back
        _result continueWith [{
            _thisArgs params ["_request", "_control"];

            _result = toJSON _this; // JSON string
            _result = controlNull ctrlWebBrowserAction ["ToBase64", _result]; // To B64 (so we know we can cleanly transfer it)

            _control ctrlWebBrowserAction ["ExecJS", format ["A3API._response('%1', '%2')", _request get "k", _result]];
        }, [_request, _control]];
    };


    //#TODO we currently require keys to be clean and not contain quotes, it would be better to just b64 them in case that changes
    // reply with result

    _result = toJSON _result; // JSON string
    _result = controlNull ctrlWebBrowserAction ["ToBase64", _result]; // To B64 (so we know we can cleanly transfer it)

    _control ctrlWebBrowserAction ["ExecJS", format ["A3API._response('%1', '%2')", _request get "k", _result]];
}];

//#TODO development, remove this
_appSection spawn {
    sleep 0.5; // Wait till its loaded
    _this ctrlWebBrowserAction ["OpenDevConsole"];
};

_appSection ctrlSetFade 0.99;
_appSection ctrlCommit 0;
