#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Debug helper for the live vehicle test suite: parks a test helicopter at an
 * empty position near the player and seats the player plus an AI copilot, so
 * every seat (driver, copilot, on foot) can be exercised automatically.
 * Repeated calls clean up the previous test helicopter and copilot first.
 *
 * Arguments:
 * 0: Seat <STRING> (optional, default "driver") "driver", "gunner" or "onfoot"
 * 1: Class <STRING> (optional, default "B_Heli_Light_01_dynamicLoadout_F")
 *
 * Return Value:
 * Result <HASHMAP> { ok, class, vehicle (netId), seat, copilot (netId) }
 * or { ok: false, error: STRING }
 *
 * Example:
 * ["driver", ""] call ace_tacphone_Vehicle_fnc_debugPrepareVehicle
 *
 * Public: No
 */

params [["_seat", "driver"], ["_class", ""]];

_seat = toLower _seat;

if (isNull player) exitWith {
    createHashMapFromArray [["ok", false], ["error", "no player"]];
};

if (_seat != "driver" && {_seat != "gunner"} && {_seat != "onfoot"}) exitWith {
    createHashMapFromArray [["ok", false], ["error", format ["unknown seat: %1", _seat]]];
};

// Resolve the helicopter class, with a config scan as fallback.
if (_class == "") then {
    _class = "B_Heli_Light_01_dynamicLoadout_F";
};
if (!isClass (configFile >> "CfgVehicles" >> _class)) then {
    private _helis = ("true" configClasses (configFile >> "CfgVehicles")) select {
        getNumber (_x >> "scope") == 2
        // isKindOf takes no Config left operand: compare class names instead.
        && {(configName _x) isKindOf "Helicopter"}
    };
    _class = if (_helis isNotEqualTo []) then { configName (_helis select 0) } else { "" };
};

if (_class == "") exitWith {
    createHashMapFromArray [["ok", false], ["error", "no helicopter class available"]];
};

// The copilot seat is the helicopter's first turret.
private _hasCopilotSeat =
    (count ("true" configClasses (configFile >> "CfgVehicles" >> _class >> "turrets"))) > 0;

if (_seat == "gunner" && {!_hasCopilotSeat}) exitWith {
    createHashMapFromArray [["ok", false], ["error", format ["%1 has no copilot seat", _class]]];
};

private _aiClass = "B_Helipilot_F";
if (!isClass (configFile >> "CfgVehicles" >> _aiClass)) then {
    _aiClass = "";
};

if (_seat == "gunner" && {_aiClass == ""}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "no AI copilot class available for the copilot seat test"]];
};

// The player must be on foot before the scene is rebuilt. The GetOut action
// (not moveOut) is used so the engine runs a real dismount, the same way a
// key press would.
if (vehicle player isNotEqualTo player) then {
    player action ["GetOut", vehicle player];
    private _outWait = 30;
    waitUntil {
        (vehicle player isEqualTo player) || {
            _outWait = _outWait - 0.1;
            _outWait <= 0
        };
    };
    if (vehicle player isNotEqualTo player) exitWith {
        createHashMapFromArray [["ok", false], ["error", "could not get the player out of the current vehicle"]];
    };
};

// Remove the test helicopter and copilot from the previous run.
if (!isNil QGVAR(debugTestVehicle)) then {
    private _oldHeli = GVAR(debugTestVehicle) param [0, objNull];
    private _oldCopilot = GVAR(debugTestVehicle) param [1, objNull];

    if (!isNull _oldCopilot && {vehicle _oldCopilot isNotEqualTo _oldCopilot}) then {
        moveOut _oldCopilot;
    };
    if (!isNull _oldHeli) then {
        deleteVehicle _oldHeli;
    };
    if (!isNull _oldCopilot) then {
        deleteVehicle _oldCopilot;
    };
    GVAR(debugTestVehicle) = objNull;
};

// Build the scene at the player: the vehicle is placed at the player's
// ground position, never the player at the vehicle. Teleporting the player
// can drop it mid-fall or mid-boarding (ACE medical and the seat state then
// go unstable, and a reverted boarding fires no GetOut event); moving the
// vehicle is deterministic. A player left in the air by a previous scene is
// clamped to the terrain (the air scenarios park their vehicle on the
// ground before finishing).
// Build the scene at a free pad around the player: findEmptyPosition
// verifies a clear area for the vehicle's collision model (the mission
// spawn is an airfield apron with parked vehicles a few metres from the
// player; a spawn there takes collision damage that can leave the engine
// part unable to start). The vehicle is placed on that pad, never the
// player at the vehicle (teleporting the player can drop it mid-fall or
// mid-boarding, ACE medical and the seat state then go unstable); the
// player walks to the pad - a walk is the player's own movement.
private _origin = getPosASL player;
private _pad = _origin findEmptyPosition [15, 100, _class];
if (typeName _pad != "ARRAY" || {count _pad < 3}) then {
    _pad = _origin findEmptyPosition [20, 500, _class];
};
if (typeName _pad != "ARRAY" || {count _pad < 3}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "no empty position for the helicopter near the player"]];
};
private _heli = createVehicle [_class, _pad, [], 0, "NONE"];
_heli setDir (_pad getDir _origin);
// Settle the spawn: a moveIn* issued in the same frame as a createVehicle
// is silently ignored (the copilot seating below relies on the same).
sleep 0.5;

// Walk (not teleport) to the boarding spot; GetInDriver needs the player
// a couple of metres from the seat.
player move (_heli getPos [2.5, 90]);
private _walkWait = 60;
waitUntil {
    (player distance2D _heli < 4) || {
        _walkWait = _walkWait - 0.5;
        _walkWait <= 0
    };
};

private _copilot = objNull;
if (_aiClass != "") then {
    // createVehicle makes an empty object; a unit needs a group.
    private _sideIndex = getNumber (configFile >> "CfgVehicles" >> _aiClass >> "side");
    private _aiSide = [east, west, independent, civilian] select _sideIndex;
    private _copilotGroup = createGroup _aiSide;
    _copilot = _copilotGroup createUnit [
        _aiClass,
        _heli getRelPos [2.5, -90],
        [],
        0,
        "NONE"
    ];
};

// moveIn* commands take the unit as the left operand (unit moveInDriver vehicle).
// A unit issued a moveIn* in the same frames as its createVehicle is silently
// ignored, so settle the copilot first. Its seating is best-effort: the live
// tests never assert on the copilot's seat.
if (!isNull _copilot) then {
    _copilot setPosATL (_heli getRelPos [2.5, -90]);
    sleep 0.3;
    if (_hasCopilotSeat) then {
        private _turret = (allTurrets _heli) select 0;
        if (_seat == "gunner") then {
            _copilot moveInDriver _heli;
        } else {
            _copilot moveInTurret [_heli, _turret];
        };
    };
};

// Stash the scene before any wait or exitWith: a failed run must still be
// deletable by the next call's cleanup.
GVAR(debugTestVehicle) = [_heli, _copilot];

// The player boards with the GetInXXXX actions (not moveIn*): the action
// runs a real boarding, the way a key press would, so the game's vehicle
// events and the phone UI see an authentic change.
if (_seat == "driver") then {
    player action ["GetInDriver", _heli];
} else {
    if (_seat == "gunner") then {
        // GetInGunner finds no seat on this vehicle class; the copilot seat
        // is the first turret, so the player boards it by turret path.
        player action ["GetInTurret", _heli, (allTurrets _heli) select 0];
    };
};

// Wait until the seating actually happened: the player's vehicle must be this
// helicopter. On foot, vehicle player is the player itself, and a stale link
// to the deleted previous vehicle must not count either. The GetIn action
// runs a boarding animation, so allow for it.
if (_seat != "onfoot") then {
    private _seatWait = 30;
    waitUntil {
        private _seated = (vehicle player isEqualTo _heli)
            && {if (_seat == "driver") then { driver _heli isEqualTo player } else { true }};
        _seated || {
            _seatWait = _seatWait - 0.1;
            _seatWait <= 0
        };
    };
    if (_seatWait <= 0) exitWith {
        createHashMapFromArray [["ok", false], ["error", format ["the player did not reach the %1 seat", _seat]]];
    };

    // The seat must hold: a reverted boarding clears the parent again without
    // firing any GetOut event.
    sleep 0.5;
    if (vehicle player isNotEqualTo _heli) exitWith {
        createHashMapFromArray [["ok", false], ["error", format ["the player was unseated from the %1 seat", _seat]]];
    };
};

createHashMapFromArray [
    ["ok", true],
    ["class", typeOf _heli],
    ["vehicle", netId _heli],
    ["seat", _seat],
    ["copilot", if (isNull _copilot) then { "" } else { netId _copilot }]
]
