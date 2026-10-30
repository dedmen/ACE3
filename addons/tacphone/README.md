ace_tacphone
===============

The Tacphone module introduces a something or other

## Display modes

The phone can be shown in one of four modes (`ace_tacphone_fnc_openDisplay`, the device key or the
"Open Phone" keybind switch between them):

- **Closed** – the phone is not shown at all, only the invisible background browser keeps running.
- **HUD** – a small always-on-screen copy (RscTitles) of the phone, for quick glances while playing.
- **Dialog** – the full, interactive phone dialog.
- **Hidden** – temporary internal state while `canShow` conditions are not met; the phone reappears as HUD when possible.

The HUD position and size are user configurable: **Settings > Game > Layout** (grid
`grid_ACE_tacPhone`).

## SQF API for addon and app authors

### Sending data to the phone

```sqf
// _target can be a single target or an array of targets:
//   "local"          - the in-game TacPhone instance
//   "<connectionId>" - one specific remote browser (websocket connection id)
//   "*"              - everyone: in-game instance plus one broadcast to all remote clients
[_targets, _message] call ace_tacphone_fnc_sendCommandToPhone // -> Bool, delivered to at least one target
```

Empty and duplicate targets are dropped, invalid entries are ignored. `"*"` is never expanded in
SQF, it is passed to the extension as a single wildcard target. When no `"local"` target is given,
the in-game phone does not receive the message.

### Reading a game file

The `main` app answers a `GetFile` request with the contents of a file in the game filesystem, or
`""` when it does not exist. This is the same command the websocket file server uses.

```sqf
// SQF
[{a: "main", c: "GetFile", path: "\z\ace\addons\tacphone\data\index.html"}, "local", {
    params ["_result"];
    systemChat str _result; // file contents
}] call ace_tacphone_fnc_dispatchRequest
```

From a web app: `networking.Request({ a: 'main', c: 'GetFile', path: 'z\\ace\\addons\\tacphone\\data\\index.html' })`.
`path` is a game filesystem path. `/` and an empty path resolve to the TacPhone `index.html`.

### Data interests (demand driven updates)

An app instance announces that it needs a named "information interest"; the game only does the
expensive work and only sends to the clients that asked. Interest names are opaque strings
namespaced by app (`"<AppName>.<feature>"`, max 128 characters, e.g. `"ACE_TacPhone_Map.markers"`).

```sqf
// Clients that currently hold the interest, [] when nobody does.
// Contains "local" if the in-game browser holds it, so the result can be passed straight to sendCommandToPhone.
private _targets = ["ACE_TacPhone_Map.markers"] call ace_tacphone_fnc_getInterestClients;
if (_targets isEqualTo []) exitWith {}; // cheap early-out, no data assembly
[_targets, _message] call ace_tacphone_fnc_sendCommandToPhone;

// CBA events, fired locally on this machine only on the real transitions:
// first client joins (0 -> 1) and last client leaves (1 -> 0). Payload is [interestName].
["ace_tacphone_interestActivated",   FUNC(onInterestActivated)]   call CBA_fnc_addEventHandler;
["ace_tacphone_interestDeactivated", FUNC(onInterestDeactivated)] call CBA_fnc_addEventHandler;
```

Register the CBA handlers in `postInit` and make them idempotent: activate adds the game event
handlers the app needs, deactivate removes exactly those. Handlers run synchronously, so keep them
small (add/remove event handlers, no data assembly).

The web side declares interests through the host (`window.InterestRegistry.acquire(name)`); the
request itself is a command of the built-in app `"main"`:

| Command | Fields | Effect |
| --- | --- | --- |
| `Interest.Set` | `interest: String`, `active: Bool` | Adds/removes this client. Idempotent, duplicates are no-ops. |
| `Interest.Clear` | – | Removes every interest of this client (page unload). |

Both are handled by the `"main"` app request processor, which receives the requesting client id.
They reply with `{ ok: Bool, error: String }` (`error` only on failure). A websocket disconnect
releases all of that connection's interests automatically.
