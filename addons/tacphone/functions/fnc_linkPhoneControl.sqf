#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Points a CT_CONTROL_REF control at the invisible background TacPhone browser and matches the browser resolution to the control size.
 *
 * Arguments:
 * 0: Reference control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [ctrl] call ace_tacphone_fnc_linkPhoneControl
 *
 * Public: No
 */

params ["_control"];

private _source = uiNamespace getVariable [QGVAR(appSection), controlNull];
if (isNull _source) exitWith { ERROR("TacPhone background browser is not available"); };

_control ctrlWebBrowserAction ["SetControlReference", _source];

private _ctrlPos = ctrlPosition _control;
_source ctrlWebBrowserAction ["SetBrowserInternalSize", (round ((_ctrlPos select 2) / pixelW)) max 1, (round ((_ctrlPos select 3) / pixelH)) max 1];
