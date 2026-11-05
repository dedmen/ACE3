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
 *
 * Return Value:
 * Delivered to the in-game phone <BOOL>. False if the phone browser is not open.
 *
 * Example:
 * [createHashMapFromArray [["a", "main"], ["c", "SomeCommand"]]] call ace_tacphone_fnc_sendCommandToPhone
 *
 * Public: No
 */

params ["_message"];

private _browserControl = uiNamespace getVariable [QGVAR(appSection), controlNull];
if (isNull _browserControl) exitWith { false };

private _messageB64 = controlNull ctrlWebBrowserAction ["ToBase64", toJSON _message];
_browserControl ctrlWebBrowserAction ["ExecJS", format ["window.TacPhone.networking.OnMessageFromGame(JSON.parse(atob('%1')))", _messageB64]];

true
