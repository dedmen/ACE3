#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * TacPhone webbrowser sent us data to process and reply to
 *
 * Arguments:
 * 0: Request <HASHMAP> ({ "a": "AppName", "c": "CommandName", ... })
 * 1: Client id <STRING> (unused by this app, provided to every request processor)
 *
 * Return Value:
 * ANY (Usually Hashmap or Promise)
 *
 * Example:
 * [] call ace_tacphone_vehicle_fnc_processBrowserRequest
 *
 * Public: No
 */

params ["_request"];

// _request is { "a": "AppName", "c": "CommandName", ... }
// AppName was already resolved, that's why we're here now

private _command = _request get "c";

if (isNil QGVAR(browserRequestHandlers)) then {
    private _handlers = createHashMapFromArray [
        ["GetVehicle", {
            call FUNC(getVehicleInfo)
        }],
        ["Do", {
            params ["_request"];

            private _action = _request getOrDefault ["action", ""];
            private _state = _request getOrDefault ["state", false];
            private _vehicleNetId = _request getOrDefault ["vehicle", ""];
            private _cargo = _request getOrDefault ["cargo", ""];

            // a. The player may not exist very early in the mission
            if (isNull player) exitWith {
                createHashMapFromArray [["ok", false], ["action", _action], ["state", _state], ["error", "no player"]];
            };

            private _vehicle = vehicle player;

            // b. On foot, the "vehicle" is the player themself
            if (_vehicle isEqualTo player) exitWith {
                createHashMapFromArray [["ok", false], ["action", _action], ["state", _state], ["error", "not in vehicle"]];
            };

            // c. Only the driver or pilot may act on the vehicle
            if (driver _vehicle isNotEqualTo player) exitWith {
                createHashMapFromArray [["ok", false], ["action", _action], ["state", _state], ["error", "not driver"]];
            };

            // d. A command queued before a vehicle change must not hit the new vehicle
            if (_vehicleNetId != netId _vehicle) exitWith {
                createHashMapFromArray [["ok", false], ["action", _action], ["state", _state], ["error", "vehicle changed"]];
            };

            // e. Capability gate, the web only hides buttons
            private _capabilities = [_vehicle] call FUNC(getCapabilities);
            private _supported = switch (_action) do {
                case "Engine": { true };
                case "Gear": { _capabilities get "canGear" };
                case "Light": { _capabilities get "canLight" };
                case "CollisionLight": { _capabilities get "canCollisionLight" };
                case "AutoHover": { _capabilities get "canAutoHover" };
                case "Hook": { _capabilities get "canSlingLoad" };
                case "Airdrop": { _capabilities get "hasCargo" };
                case "ActiveSensors": { _capabilities get "canActiveSensors" };
                case "WheelsBrake": { _capabilities get "canWheelsBrake" };
                default { false };
            };
            if (!_supported) exitWith {
                createHashMapFromArray [["ok", false], ["action", _action], ["state", _state], ["error", "unsupported"]];
            };

            if (isNil QGVAR(doRate)) then {
                GVAR(doRate) = createHashMap;
                GVAR(doLastState) = createHashMap;
            };

            // f. Rate limit: max 5 executed commands per second per action (sliding 1 s window)
            private _now = CBA_missionTime;
            private _window = GVAR(doRate) getOrDefault [_action, []];
            _window = _window select { _now - _x <= 1 };
            if (count _window >= 5) exitWith {
                createHashMapFromArray [["ok", false], ["action", _action], ["state", _state], ["error", "rate limited"]];
            };

            // g. Repeat suppression: the same action+state within 200 ms is acknowledged without
            // executing. Airdrop is exempt: it is not idempotent (every execution drops an item),
            // so a repeat must run fnc_doAirdrop and hit the single-drop guard instead of being
            // silently acknowledged as success.
            private _stateKey = format ["%1|%2", _action, _state];
            if (_action != "Airdrop" && {GVAR(doLastState) getOrDefault [_stateKey, -1] >= _now - 0.2}) exitWith {
                createHashMapFromArray [["ok", true], ["action", _action], ["state", _state]];
            };

            private _result = [_vehicle, _action, _state, _cargo] call FUNC(doControl);
            private _ok = _result param [0, false];
            private _detail = _result param [1, ""];

            if (_ok) then {
                // Only executed commands count against the limit
                GVAR(doRate) set [_action, _window + [_now]];
                GVAR(doLastState) set [_stateKey, _now];
            };

            private _reply = createHashMap;
            _reply set ["ok", _ok];
            _reply set ["action", _action];
            _reply set ["state", _state];
            if (_ok) then {
                // Hook carries the picked cargo id, Airdrop the dropped item id
                if (_action in ["Hook", "Airdrop"]) then {
                    _reply set ["cargo", _detail];
                };
            } else {
                _reply set ["error", _detail];
            };

            _reply
        }]
#ifdef __A3_DEBUG__
        ,
        ["Debug.VehicleInfo", {
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            private _info = call FUNC(debugVehicleInfo);
            _info set ["ok", true];
            _info
        }],
        ["Debug.PrepareVehicle", {
            params ["_request"];
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            // Debug-only scene builder for the live test suite: spawns a test
            // helicopter near the player and seats the player plus an AI copilot.
            // It waits for dismount and boarding animations, which the request
            // context cannot do (no suspending), so it runs as a spawned
            // script: the dispatcher attaches a continueWith to the returned
            // handle and replies with the script's return value.
            [
                _request getOrDefault ["seat", "driver"],
                _request getOrDefault ["class", ""]
            ] spawn FUNC(debugPrepareVehicle)
        }],
        ["Debug.ApplyFlight", {
            // Debug-only scene mover for the live Air HUD suite: teleports the
            // player's vehicle and/or sets its attitude and velocity, so the
            // 20 Hz state stream can be exercised without flying. Every field
            // is optional and must be a 3-vector; the response lists what was
            // applied. The player must be the driver (same gate as Do).
            params ["_request"];
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            if (isNull player) exitWith {
                createHashMapFromArray [["ok", false], ["error", "no player"]];
            };

            private _vehicle = vehicle player;
            if (_vehicle isEqualTo player) exitWith {
                createHashMapFromArray [["ok", false], ["error", "not in vehicle"]];
            };
            if (driver _vehicle isNotEqualTo player) exitWith {
                createHashMapFromArray [["ok", false], ["error", "not driver"]];
            };

            private _applied = [];

            private _pos = _request getOrDefault ["pos", []];
            if (count _pos == 3) then {
                _vehicle setPosATL _pos;
                _applied pushBack "pos";
            };

            private _posasl = _request getOrDefault ["posASL", []];
            if (count _posasl == 3) then {
                _vehicle setPosASL _posasl;
                _applied pushBack "posASL";
            };

            private _dir = _request getOrDefault ["dir", []];
            private _up = _request getOrDefault ["up", []];
            if (count _dir == 3 && {count _up == 3}) then {
                _vehicle setVectorDirAndUp [_dir, _up];
                _applied pushBack "attitude";
            };

            private _vms = _request getOrDefault ["velocityModelSpace", []];
            if (count _vms == 3) then {
                _vehicle setVelocityModelSpace _vms;
                _applied pushBack "velocityModelSpace";
            };

            private _vel = _request getOrDefault ["velocity", []];
            if (count _vel == 3) then {
                _vehicle setVelocity _vel;
                _applied pushBack "velocity";
            };

            createHashMapFromArray [["ok", true], ["applied", _applied]]
        }],
        ["Debug.AddCargo", {
            // Debug-only scene loader for the live cargo suite: puts a test
            // crate into the player's vehicle through the cargo addon's own
            // load path, so the inventory events and the Vehicle.Cargo push
            // fire for real. The player must be the driver (same gate as Do).
            params ["_request"];
            if (!(missionNamespace getVariable ["ace_tacphone_allowDebug", false])) exitWith {
                createHashMapFromArray [["ok", false], ["error", "debug mode is disabled"]];
            };

            [_request getOrDefault ["class", ""]] call FUNC(debugAddCargo)
        }]
#endif
    ];

    GVAR(browserRequestHandlers) = compileFinal _handlers;
};

// `get` returns an empty array for missing keys, so check the key itself.
if (!(_command in GVAR(browserRequestHandlers))) exitWith {
    diag_log format ["[TacPhone] Unknown Vehicle command: %1", _command];
    createHashMapFromArray [["ok", false], ["error", format ["unknown command: %1", _command]]];
};

private _handler = (GVAR(browserRequestHandlers)) get _command;

[_request] call _handler;
