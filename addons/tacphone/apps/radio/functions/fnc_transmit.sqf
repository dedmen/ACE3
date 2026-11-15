#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Starts, keeps alive, or ends a transmission driven by a phone client.
 * active: true is both the start and the keepalive; the keepalive is the only
 * thing that extends a transmission, and FUNC(txWatchdog) is the authority that
 * ends it when the page goes silent, the player dies, or the radio goes away.
 *
 * Arguments:
 * 0: Radio id <STRING>
 * 1: Channel <NUMBER> (1..8)
 * 2: The additional channel <BOOL>
 * 3: Active <BOOL> (true starts or keepalives, false stops)
 * 4: Token <STRING> (unique per transmission; an empty token forces a stop)
 * 5: Client id <STRING> (the requester, must hold INTEREST_RADIOS)
 *
 * Return Value:
 * Reply <HASHMAP> ({ ok, radioId, channel, token, error? })
 *
 * Example:
 * ["tf_anprc152", 3, false, true, "a1b2c3", "local"] call ace_tacphone_radio_fnc_transmit
 *
 * Public: No
 */

params [["_radioId", ""], ["_channel", 1], ["_additional", false], ["_active", true], ["_token", ""], ["_clientId", "local"]];

// The radio must still be in the player's current inventory, never trust the caller
private _radio = [_radioId] call FUNC(getRadioById);
if (isNil "_radio") exitWith {
    createHashMapFromArray [["ok", false], ["error", "radioGone"]];
};

// Transmit requires the radios interest; this is what makes interest release a stop signal
if (!(_clientId in ([INTEREST_RADIOS] call EFUNC(tacphone,getInterestClients)))) exitWith {
    createHashMapFromArray [["ok", false], ["error", "notHoldingInterest"]];
};

// A non-local client needs the allowRemoteTransmit option (default on). The
// early exit is top-level: nested in a `then` block it would only exit the
// block and the transmission would start anyway.
private _options = GVAR(options) getOrDefault [_clientId, createHashMap];
if (_clientId != "local" && {!(_options getOrDefault ["allowRemoteTransmit", true])}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "forbidden"]];
};

// The player must be able to use a radio
if (!call TFAR_fnc_isAbleToUseRadio) exitWith {
    call TFAR_fnc_unableToUseHint;
    createHashMapFromArray [["ok", false], ["error", "unable"]];
};

// The player is already keying a handset in game through TFAR
if (GVAR(inGameTx) != "") exitWith {
    createHashMapFromArray [["ok", false], ["error", "inGameTransmit"]];
};

private _tx = GVAR(tx);

// Keepalive: the same token is already transmitting, only refresh seen. Both
// early exits are top-level: inside the `then` block below, an `exitWith`
// would only exit that block, so every keepalive would force-stop and
// re-start the transmission instead of just refreshing `seen`.
if (_active && {!isNil "_tx"} && {(_tx get "token") == _token}) exitWith {
    _tx set ["seen", diag_tickTime];
    createHashMapFromArray [
        ["ok", true],
        ["radioId", _tx get "radio"],
        ["channel", _tx get "channel"],
        ["token", _tx get "token"]
    ]
};

if (_active && {_channel < 1 || {_channel > 8}}) exitWith {
    createHashMapFromArray [["ok", false], ["error", "badChannel"]];
};

if (_active) then {

    // One transmitter at a time: any other transmission is force-ended first
    if (!isNil "_tx") then {
        ["switched"] call FUNC(stopTransmit);
    };

    // The frequency is read immediately before the call, never cached;
    // do*Transmit expects it as a string
    private _isLr = _radio isEqualType [];
    private _frequency = str ([_radio, _channel] call TFAR_fnc_getChannelFrequency);
    // Protocol 1..8 -> the base get*Channel returns, matching do*Transmit
    private _tfarChannel = _channel - 1;

    // The programmatic transmit fires TFAR_event_OnTangent for the player's
    // own unit a few frames later; park the expected self-event so the
    // tangent handler consumes it instead of mirroring our own start as an
    // in-game key press.
    GVAR(ownTangent) = [_radioId, true, diag_tickTime + SELF_TANGENT_WINDOW];

    if (_isLr) then {
        [_radio, _tfarChannel, _frequency, _additional] call TFAR_fnc_doLRTransmit;
    } else {
        [_radio, _tfarChannel, _frequency, _additional] call TFAR_fnc_doSRTransmit;
    };

    GVAR(tx) = createHashMapFromArray [
        ["radio", _radioId],
        ["channel", _channel],
        ["additional", _additional],
        ["token", _token],
        ["client", _clientId],
        ["source", "web"],
        ["since", diag_tickTime],
        ["seen", diag_tickTime]
    ];

    // The watchdog only runs while a transmission is active
    if (isNil QGVAR(txPFH)) then {
        GVAR(txPFH) = [FUNC(txWatchdog), TX_WATCHDOG_INTERVAL, []] call CBA_fnc_addPerFrameHandler;
    };

    // Every transmit transition is pushed immediately, never coalesced
    [createHashMapFromArray [
        ["a", "ACE_TacPhone_Radio"],
        ["c", "Radio.Transmit"],
        ["radioId", _radioId],
        ["channel", _channel],
        ["additional", _additional],
        ["active", true],
        ["source", "web"],
        ["token", _token]
    ]] call EFUNC(tacphone,sendCommandToPhone);

    // Tell the in-game page when a remote client keys the radio (_options was
    // read at the top of the function)
    if (_clientId != "local") then {
        if (_options getOrDefault ["notifyRemoteTransmit", true]) then {
            [createHashMapFromArray [
                ["a", "ACE_TacPhone_Radio"],
                ["c", "Radio.ExternalTransmit"],
                ["radioId", _radioId],
                ["channel", _channel],
                ["clientId", _clientId]
            ]] call EFUNC(tacphone,sendCommandToPhone);
        };
    };

    createHashMapFromArray [
        ["ok", true],
        ["radioId", _radioId],
        ["channel", _channel],
        ["token", _token]
    ]
};

// active: false
if (isNil "_tx" || {(_tx get "token") != _token && {_token != ""}}) exitWith {
    // Nothing to end; a stale nack for an old token must not stop a newer transmission
    createHashMapFromArray [
        ["ok", true],
        ["radioId", _radioId],
        ["channel", _channel],
        ["token", _token]
    ]
};

[] call FUNC(stopTransmit);

createHashMapFromArray [
    ["ok", true],
    ["radioId", _radioId],
    ["channel", _channel],
    ["token", _token]
]
