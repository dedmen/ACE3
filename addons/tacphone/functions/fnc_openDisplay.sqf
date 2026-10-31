#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Changes the TacPhone display mode (closed, HUD or interactive dialog).
 *
 * Arguments:
 * 0: Display mode to show <NUMBER> (default: -1 = toggle)
 *
 * Return Value:
 * None
 *
 * Example:
 * [1] call ace_tacphone_fnc_openDisplay
 *
 * Public: No
 */
params [["_newDisplayShowMode", -1, [0]]];
private _oldShowMode = GVAR(currentShowMode);

if (_newDisplayShowMode == -1) then {
    //Toggle mode button:
    if (_oldShowMode in [DISPLAY_MODE_HUD, DISPLAY_MODE_HIDDEN]) then {_newDisplayShowMode = DISPLAY_MODE_DIALOG;};
    if (_oldShowMode in [DISPLAY_MODE_DIALOG, DISPLAY_MODE_CLOSED]) then {_newDisplayShowMode = DISPLAY_MODE_HUD;};
};

if ((_newDisplayShowMode == DISPLAY_MODE_HUD) && {!([DISPLAY_MODE_HUD] call FUNC(canShow))}) then {_newDisplayShowMode = DISPLAY_MODE_HIDDEN;};
if ((_newDisplayShowMode == DISPLAY_MODE_DIALOG) && {!([DISPLAY_MODE_DIALOG] call FUNC(canShow))}) then {_newDisplayShowMode = DISPLAY_MODE_HIDDEN;};

if (_newDisplayShowMode == _oldShowMode) exitWith {};

//Set the mode before closing the dialog so its onUnload (dialogClosedEH) does not reopen the HUD
GVAR(currentShowMode) = _newDisplayShowMode;

//Apps that track presence (Messaging) recompute the visibility of the local client
[QGVAR(displayModeChanged), [_newDisplayShowMode]] call CBA_fnc_localEvent;

private _dialogDisplay = uiNamespace getVariable [QGVAR(InteractiveDialog), displayNull];
if (!isNull _dialogDisplay) then {
    _dialogDisplay closeDisplay 0;
};

private _layer = QGVAR(HUDDisplay) call BIS_fnc_rscLayer;

switch (_newDisplayShowMode) do {
    case (DISPLAY_MODE_HUD): {
        [] call FUNC(loadPhoneHud);
    };
    case (DISPLAY_MODE_DIALOG): {
        _layer cutText ["", "PLAIN"];
        [] call FUNC(loadPhoneForeground);
    };
    default {
        _layer cutText ["", "PLAIN"];
    };
};

if ((_oldShowMode == DISPLAY_MODE_CLOSED) && {GVAR(currentShowMode) != DISPLAY_MODE_CLOSED}) then {
    //Keep the display state in sync with inventory / interaction state
    [{
        params ["_args", "_idPFH"];
        _args params ["_player"];
        if ((isNull ACE_player) || {!alive ACE_player} || {ACE_player != _player} || {!("ACE_Tacphone" in (ACE_player call EFUNC(common,uniqueItems)))} || {GVAR(currentShowMode) == DISPLAY_MODE_CLOSED}) then {
            if (GVAR(currentShowMode) != DISPLAY_MODE_CLOSED) then {
                [DISPLAY_MODE_CLOSED] call FUNC(openDisplay);
            };
            [_idPFH] call CBA_fnc_removePerFrameHandler;
        } else {
            if (GVAR(currentShowMode) == DISPLAY_MODE_HIDDEN) then {
                if ([DISPLAY_MODE_HUD] call FUNC(canShow)) then {
                    [DISPLAY_MODE_HUD] call FUNC(openDisplay);
                };
            } else {
                if !([GVAR(currentShowMode)] call FUNC(canShow)) then {
                    [DISPLAY_MODE_HIDDEN] call FUNC(openDisplay);
                };
            };
        };
    }, 0.1, [ACE_player]] call CBA_fnc_addPerFrameHandler;
};
