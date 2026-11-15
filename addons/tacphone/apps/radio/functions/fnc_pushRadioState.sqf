#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Coalesced Radio.State push. No matter how many events fire within one frame
 * (or the pushMs window), exactly one snapshot is assembled and sent.
 * The per-client pushMs floor stored from GetState is honoured as the delay:
 * the slowest interested client sets it, clamped to MAX_PUSH_MS.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call ace_tacphone_radio_fnc_pushRadioState
 *
 * Public: No
 */

if (GVAR(pushQueued)) exitWith {};
GVAR(pushQueued) = true;

// The slowest interested client sets the delay
private _delayMs = 0;
{
    _delayMs = _delayMs max (GVAR(pushMsByClient) getOrDefault [_x, 0]);
} forEach keys GVAR(pushMsByClient);
_delayMs = _delayMs min MAX_PUSH_MS;

private _push = {
    GVAR(pushQueued) = false;

    // Cheap early-out before any data assembly: nobody is interested
    if (([INTEREST_RADIOS] call EFUNC(tacphone,getInterestClients)) isEqualTo []) exitWith {};

    // The revision was already committed by the state change that queued
    // this push (FUNC(commitRevision)); the push only broadcasts it.
    private _snapshot = [] call FUNC(assembleAllRadios);

    private _message = createHashMapFromArray [
        ["a", "ACE_TacPhone_Radio"],
        ["c", "Radio.State"],
        ["radios", _snapshot get "radios"],
        ["tx", _snapshot get "tx"],
        ["ready", _snapshot get "ready"],
        ["revision", _snapshot get "revision"]
    ];

    [_message] call EFUNC(tacphone,sendCommandToPhone);
};

// More than one frame: wait the requested floor instead of execNextFrame
if (_delayMs > 16) then {
    [_push, [], _delayMs / 1000] call CBA_fnc_waitAndExecute;
} else {
    [_push] call CBA_fnc_execNextFrame;
};
