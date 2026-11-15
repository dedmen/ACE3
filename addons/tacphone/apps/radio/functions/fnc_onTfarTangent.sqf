#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * TFAR_event_OnTangent handler: the player keys or releases a real handset.
 * Tracks GVAR(inGameTx) so a web Transmit cannot start while the player is
 * keying in game, mirrors the game start and end to the web (source: "game"),
 * and ends a web-driven transmission on the matching release (reason:
 * tangentEnd).
 *
 * Arguments:
 * 0: Unit <OBJECT> (the unit keying the radio)
 * 1: Radio handle <STRING or ARRAY> (class string for SR, [object, qualifier] for LR)
 * 2: Type <ANY> (unused)
 * 3: The additional channel <BOOL> (no conversion, as fired by TFAR)
 * 4: Start <BOOL> (true on key down, false on key up)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["TFAR_event_OnTangent", ace_tacphone_radio_fnc_onTfarTangent] call CBA_fnc_addEventHandler
 *
 * Public: No
 */

params ["_unit", "_radio", "_type", "_isAdditional", "_start"];

if (_unit != player) exitWith {};

private _radioId = [_radio] call FUNC(encodeRadioId);

// A web transmit (start or end) fires this same event for the player's own
// unit a few frames later. Mirroring it would race the web push and mark our
// own key press as in-game, so the expected self-event parked by
// FUNC(transmit)/FUNC(stopTransmit) is consumed here instead. The expiry
// bounds a self-event that never arrives.
private _own = GVAR(ownTangent);

// A real key press on this radio retires a parked self-release: the release
// that follows the press is the player's own, and consuming it would wedge
// GVAR(inGameTx) (set for the press below) with no release ever mirrored.
// No exit: the press itself is real and falls through to the mirror.
if (_start && {count _own == 3} && {(_own select 0) == _radioId}
    && {(_own select 1) == false}) then {
    GVAR(ownTangent) = [];
    _own = [];
};

// The self-event a web transmit/stop parked, expected a few frames later:
// consume it instead of mirroring (mirroring would race the web push).
// Anything else - including a real key press with no parked event - is real
// and falls through to the mirror below.
if (count _own == 3 && {(_own select 0) == _radioId}
    && {(_own select 1) == _start} && {diag_tickTime <= (_own select 2)}) exitWith {
    GVAR(ownTangent) = [];
};

// TFAR base -> protocol: -1 (none) -> 0, 0..7 -> 1..8
private _isLr = _radio isEqualType [];
private _rawChannel = if (_isLr) then {
    if (_isAdditional) then { _radio call TFAR_fnc_getAdditionalLrChannel } else { _radio call TFAR_fnc_getLrChannel }
} else {
    if (_isAdditional) then { _radio call TFAR_fnc_getAdditionalSwChannel } else { _radio call TFAR_fnc_getSwChannel }
};
private _channel = if (_rawChannel == -1) then { 0 } else { _rawChannel + 1 };

if (_start) then {
    // The player is keying a handset in game: web transmits are blocked while held
    GVAR(inGameTx) = _radioId;

    // Mirror the game-side start to the web (the web PTT machine treats it as
    // an external transmission, like a remote one)
    [createHashMapFromArray [
        ["a", "ACE_TacPhone_Radio"],
        ["c", "Radio.Transmit"],
        ["radioId", _radioId],
        ["channel", _channel],
        ["additional", _isAdditional],
        ["active", true],
        ["source", "game"]
    ]] call EFUNC(tacphone,sendCommandToPhone);
} else {
    // Key released in game
    if (GVAR(inGameTx) == _radioId) then {
        GVAR(inGameTx) = "";

        // Mirror the game-side end, so the web "transmitting in game" state
        // leaves on release (a web transmission on the same radio gets its
        // own stop push from FUNC(stopTransmit) below)
        [createHashMapFromArray [
            ["a", "ACE_TacPhone_Radio"],
            ["c", "Radio.Transmit"],
            ["radioId", _radioId],
            ["channel", _channel],
            ["additional", _isAdditional],
            ["active", false],
            ["source", "game"]
        ]] call EFUNC(tacphone,sendCommandToPhone);
    };

    // A web client was driving this radio: the in-game key up ends it
    private _tx = GVAR(tx);
    if (!isNil "_tx" && {(_tx get "radio") == _radioId} && {(_tx get "source") == "web"}) then {
        ["tangentEnd"] call FUNC(stopTransmit);
    };
};
