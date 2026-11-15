#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Force-ends the active transmission with a reason. Every safety path (interest
 * release, death, respawn, vehicle change, mission end, watchdog, in-game PTT
 * release, a new transmission) goes through here, so a transmission can never
 * get stuck. Idempotent: a second call finds nothing to end and returns false.
 *
 * Arguments:
 * 0: Reason <STRING> (detail of the Radio.Transmit stop push, "" for a normal web release)
 *
 * Return Value:
 * Ended a transmission <BOOL>
 *
 * Example:
 * ["interest"] call ace_tacphone_radio_fnc_stopTransmit
 *
 * Public: No
 */

params [["_reason", ""]];

if (isNil QGVAR(tx)) exitWith { false };

// Capture the state first, then drop it: nothing else may end this transmission
private _radioId = GVAR(tx) get "radio";
private _channel = GVAR(tx) get "channel";
private _additional = GVAR(tx) get "additional";
private _source = GVAR(tx) get "source";
// The stop push carries the token of the ended session, like the start push:
// a same-radio re-key right after the stop is otherwise indistinguishable
private _token = GVAR(tx) get "token";
GVAR(tx) = nil;

// The watchdog only runs while a transmission is active
if (!isNil QGVAR(txPFH)) then {
    [GVAR(txPFH)] call CBA_fnc_removePerFrameHandler;
    GVAR(txPFH) = nil;
};

// Resolve the radio again; if it is gone, nothing to end
private _radio = [_radioId] call FUNC(getRadioById);

if (!isNil "_radio") then {
    private _isLr = _radio isEqualType [];
    // do*TransmitEnd expects the frequency as a string
    private _frequency = str ([_radio, _channel] call TFAR_fnc_getChannelFrequency);
    // Protocol 1..8 -> the base get*Channel returns, matching do*Transmit
    private _tfarChannel = _channel - 1;

    // Same self-event guard as on start: the programmatic end fires the
    // tangent release for the player's own unit a few frames later.
    GVAR(ownTangent) = [_radioId, false, diag_tickTime + SELF_TANGENT_WINDOW];

    if (_isLr) then {
        [_radio, _tfarChannel, _frequency, _additional] call TFAR_fnc_doLRTransmitEnd;
    } else {
        [_radio, _tfarChannel, _frequency, _additional] call TFAR_fnc_doSRTransmitEnd;
    };
};

// Push the stop immediately, never coalesced (a delayed TX frame is a bug)
[createHashMapFromArray [
    ["a", "ACE_TacPhone_Radio"],
    ["c", "Radio.Transmit"],
    ["radioId", _radioId],
    ["channel", _channel],
    ["additional", _additional],
    ["active", false],
    ["source", _source],
    ["token", _token],
    ["reason", _reason]
]] call EFUNC(tacphone,sendCommandToPhone);

true
