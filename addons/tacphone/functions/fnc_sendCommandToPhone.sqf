#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Send data to the currently open TacPhone instance
 *
 * Arguments:
 * String - Target to send to, "local" to send to in-game client instance, Websocket connection ID to send to a specific remote browser instance, "*" to send to everyone
 * HashMap - The message to be sent. Must be of structure { a: "appName", c: "command", ... }
 *
 * Return Value:
 * Bool - Whether send was successful, returns false if TacPhone is not open and there is no instance to send data to
 *
 * Example:
 * [] call ace_tacphone_fnc_sendCommandToPhone
 *
 * Public: No
 */

params ["_target", "_message"];

if (_target in ["local", "*"]) then {
    // Send to local phone instance

    private _browserControl = uiNamespace getVariable [QGVAR(appSection), controlNull];

    if (isNull _browserControl) exitWith {false}; // Phone not open

    _message = toJSON _message; // JSON string
    _message = controlNull ctrlWebBrowserAction ["ToBase64", _message];
    diag_log ["send", _message];
    _browserControl ctrlWebBrowserAction ["ExecJS", format ["window.Networking.OnMessageFromGame(JSON.parse(atob('%1')))", _message]];
};

if (_target != "local") then {
    // Send to remote instance connected via WebSocket

    private _wrapped = createHashMap;
    _wrapped set ["k", "command"]; // Tell Networking.ts NetworkingWebsocket.constructor onmessage, that this is a message from game
    _wrapped set ["d", _message]; // Tell Networking.ts NetworkingWebsocket.constructor onmessage, that this is a message from game

    "arma_webhost" callExtension ["SendTo", [_target, toJSON _wrapped]];
};
