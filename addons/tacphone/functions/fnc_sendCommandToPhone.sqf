#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Send a game message to the in-game TacPhone instance.
 *
 * The in-game web UI displays the message and broadcasts it to every web
 * client. Target lists no longer exist: relay and LAN fan-out is owned by the
 * web UI hub.
 *
 * Arguments:
 * 0: The message to be sent <HASHMAP>. Must be of structure { a: "appName", c: "command", ... }
 * 1: Quiet <BOOL> (optional, default false). True marks the drop as expected
 *    (the caller knows the phone may be closed) and suppresses the RPT line.
 *
 * Return Value:
 * Delivered to the in-game phone <BOOL>. False if the phone browser is not open.
 *
 * Example:
 * [createHashMapFromArray [["a", "main"], ["c", "SomeCommand"]]] call ace_tacphone_fnc_sendCommandToPhone
 *
 * Public: No
 */

params ["_message", ["_quiet", false]];

private _browserControl = uiNamespace getVariable [QGVAR(appSection), controlNull];
if (isNull _browserControl) exitWith {
    // The push is dropped here, silently otherwise; this is the only failure
    // point of the function, so make it visible in the RPT unless the caller
    // marked the drop as expected (quiet).
    if (!_quiet) then {
        diag_log format ["[TacPhone] sendCommandToPhone dropped %1: no in-game browser control", _message getOrDefault ["c", ""]];
    };
    false
};

private _messageB64 = controlNull ctrlWebBrowserAction ["ToBase64", toJSON _message];
_browserControl ctrlWebBrowserAction ["ExecJS", format ["window.TacPhone.networking.OnMessageFromGame(JSON.parse(atob('%1')))", _messageB64]];

true
