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

    // { k: "keystring", d: {...} }
    private _data = _request get "d";

    // The in-game browser is the client "local"
    [_data, "local", {
        params ["_result", "_args"];
        _args params ["_request", "_control"];

        //#TODO we currently require keys to be clean and not contain quotes, it would be better to just b64 them in case that changes
        // reply with result
        private _resultB64 = toJSON _result; // JSON string
        _resultB64 = controlNull ctrlWebBrowserAction ["ToBase64", _resultB64]; // To B64 (so we know we can cleanly transfer it)

        _control ctrlWebBrowserAction ["ExecJS", format ["A3API._response('%1', '%2')", _request get "k", _resultB64]];
    }, [_request, _control]] call FUNC(dispatchRequest);
}];

//#TODO development, remove this
_appSection spawn {
    sleep 0.5; // Wait till its loaded
    _this ctrlWebBrowserAction ["OpenDevConsole"];
};

_appSection ctrlSetFade 0.99;
_appSection ctrlCommit 0;
