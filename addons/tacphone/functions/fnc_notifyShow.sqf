#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Renders the "Notify.Show" main command as a BIS notification on the local
 * player's screen. Suppressed while the phone HUD or dialog is open (without
 * consuming the rate limit), and limited to NOTIFY_MAX_PER_WINDOW notifications
 * per rolling NOTIFY_WINDOW_SECONDS window of mission time.
 *
 * Arguments:
 * 0: Request data <HASHMAP> ({ "title": <STRING>, "body": <STRING>, "app": <STRING>, "style": <STRING> ("info", "success" or "alert"), "chat": <BOOL> })
 *
 * Return Value:
 * Result <HASHMAP> ({ "ok": true, "shown": true } or { "ok": true, "shown": false, "reason": "phone open" | "rate limited" })
 *
 * Example:
 * createHashMapFromArray [["title", "New message"]] call ace_tacphone_fnc_notifyShow
 *
 * Public: No
 */
params ["_request"];

private _title = _request getOrDefault ["title", ""];
private _body = _request getOrDefault ["body", ""];
private _app = _request getOrDefault ["app", ""];
private _style = _request getOrDefault ["style", "info"];
private _chat = _request getOrDefault ["chat", false];

// Newlines become spaces, angle brackets are dropped (the notification UI
// does not render markup).
_title = _title regexReplace ["\\n", " "];
_title = _title regexReplace ["\\r", " "];
_title = _title regexReplace ["<", ""];
_title = _title regexReplace [">", ""];
_body = _body regexReplace ["\\n", " "];
_body = _body regexReplace ["\\r", " "];
_body = _body regexReplace ["<", ""];
_body = _body regexReplace [">", ""];

if (count _title > NOTIFY_TITLE_MAX) then { _title = _title select [0, NOTIFY_TITLE_MAX] };
if (count _body > NOTIFY_BODY_MAX) then { _body = _body select [0, NOTIFY_BODY_MAX] };

private _now = time;
private _times = localNamespace getVariable [QGVAR(notifyTimes), []];
_times = _times select {_x > (_now - NOTIFY_WINDOW_SECONDS)};
if (count _times >= NOTIFY_MAX_PER_WINDOW) exitWith {
    diag_log "[TacPhone] Notify.Show rate limited";
    createHashMapFromArray [["ok", true], ["shown", false], ["reason", "rate limited"]];
};

if (GVAR(currentShowMode) in [DISPLAY_MODE_HUD, DISPLAY_MODE_DIALOG]) exitWith {
    createHashMapFromArray [["ok", true], ["shown", false], ["reason", "phone open"]];
};

private _icon = ((GVAR(AppInfo) getOrDefault [_app, createHashMap]) getOrDefault ["icon", ""]);

private _template = switch (toLower _style) do {
    case "success": { QGVAR(NotifySuccess) };
    case "alert": { QGVAR(NotifyAlert) };
    default { QGVAR(NotifyInfo) };
};

[ _template, [_title, _body, _icon] ] call BIS_fnc_showNotification;

if (_chat) then {
    private _line = if (_body == "") then {
        format ["[%1]", _title]
    } else {
        format ["[%1] %2", _title, _body]
    };
    systemChat _line;
};

_times pushBack _now;
localNamespace setVariable [QGVAR(notifyTimes), _times];
createHashMapFromArray [["ok", true], ["shown", true]];
