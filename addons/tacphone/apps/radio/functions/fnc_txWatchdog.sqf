#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Per-frame watchdog body, running at TX_WATCHDOG_INTERVAL only while a
 * transmission is active (started by FUNC(transmit), removed by FUNC(stopTransmit)).
 * Ends the transmission when the keepalive goes stale, the player is gone,
 * the radio is gone, or the owner stopped holding the interest.
 *
 * Arguments:
 * 0: PFH arguments <ARRAY> (unused)
 * 1: PFH handle <NUMBER> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * [ace_tacphone_radio_fnc_txWatchdog, 0.5, []] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params ["_args", "_handle"];

private _tx = GVAR(tx);
if (isNil "_tx") exitWith {};

private _radioId = _tx get "radio";
private _owner = _tx get "client";
private _reason = "";

// TFAR_fnc_LRRadiosList recurses infinitely with a null player, so test it first.
if (isNull player) then { _reason = "noPlayer"; };
if (_reason == "" && {!alive player}) then { _reason = "dead"; };
if (_reason == "") then {
    if ((_tx get "seen") + TX_KEEPALIVE_TIMEOUT < diag_tickTime) then { _reason = "stale"; };
};
if (_reason == "") then {
    // The kit enumeration is the expensive check (TFAR radios lists per call);
    // it is cached for RADIO_IDS_CACHE_TTL so a long latched transmission does
    // not re-enumerate the kit every tick. The TTL bounds how long a dropped
    // radio can stay undetected here; the TFAR events and the other stop
    // paths cover the rest.
    private _cached = GVAR(radioIdsCache);
    if ((count _cached) != 2 || {(_cached select 1) < diag_tickTime}) then {
        GVAR(radioIdsCache) = [call FUNC(getRadioIds), diag_tickTime + RADIO_IDS_CACHE_TTL];
    };
    if !(_radioId in (GVAR(radioIdsCache) select 0)) then {
        _reason = "radioGone";
    };
};
if (_reason == "" && {!(_owner in ([INTEREST_RADIOS] call EFUNC(tacphone,getInterestClients)))}) then {
    _reason = "noInterest";
};

if (_reason != "") then {
    [_reason] call FUNC(stopTransmit);
    // Like every other safety path: commit the revision and queue the push,
    // or the web radio list stays stale on a radioGone drop that no TFAR
    // event reports.
    call FUNC(commitRevision);
    call FUNC(pushRadioState);
};
