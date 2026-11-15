#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Single CBA interest transition handler for the Radio app.
 * Called from the "ace_tacphone_interestActivated" / "ace_tacphone_interestDeactivated"
 * events, idempotent for the INTEREST_RADIOS branch.
 *
 * Arguments:
 * 0: Interest name <STRING>
 * 1: Interest became active <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ACE_TacPhone_Radio.radios", true] call ace_tacphone_radio_fnc_onInterestChanged
 *
 * Public: No
 */

params [["_interest", ""], ["_active", false]];

if (_interest != INTEREST_RADIOS) exitWith {};

if (_active) then {
    // Install the TFAR event handlers exactly once (duplicate activation must not register twice)
    if (isNil QGVAR(tfarEventHandlers) || {!GVAR(tfarHandlersActive)}) then {
        private _handlers = createHashMap;

        _handlers set ["TFAR_event_OnTangent", ["TFAR_event_OnTangent", FUNC(onTfarTangent)] call CBA_fnc_addEventHandler];
        _handlers set ["TFAR_event_OnSWchannelSet", ["TFAR_event_OnSWchannelSet", FUNC(onTfarRadioEvent)] call CBA_fnc_addEventHandler];
        _handlers set ["TFAR_event_OnLRchannelSet", ["TFAR_event_OnLRchannelSet", FUNC(onTfarRadioEvent)] call CBA_fnc_addEventHandler];
        _handlers set ["TFAR_event_OnSWstereoSet", ["TFAR_event_OnSWstereoSet", FUNC(onTfarRadioEvent)] call CBA_fnc_addEventHandler];
        _handlers set ["TFAR_event_OnLRstereoSet", ["TFAR_event_OnLRstereoSet", FUNC(onTfarRadioEvent)] call CBA_fnc_addEventHandler];
        _handlers set ["TFAR_event_OnFrequencyChanged", ["TFAR_event_OnFrequencyChanged", FUNC(onTfarRadioEvent)] call CBA_fnc_addEventHandler];
        _handlers set ["TFAR_event_OnFrequencyChangedFromUI", ["TFAR_event_OnFrequencyChangedFromUI", FUNC(onTfarRadioEvent)] call CBA_fnc_addEventHandler];
        _handlers set ["TFAR_event_OnRadiosReceived", ["TFAR_event_OnRadiosReceived", FUNC(onTfarRadioEvent)] call CBA_fnc_addEventHandler];

        GVAR(tfarEventHandlers) = _handlers;
        GVAR(tfarHandlersActive) = true;
    };

    // Give the new client(s) a fix immediately instead of waiting for a TFAR event
    call FUNC(pushRadioState);
} else {
    // Remove the TFAR handlers, not installed means nothing to remove
    if (!isNil QGVAR(tfarEventHandlers) && {GVAR(tfarHandlersActive)}) then {
        private _handlers = GVAR(tfarEventHandlers);

        {
            private _id = _handlers get _x;
            if (!isNil "_id") then {
                [_x, _id] call CBA_fnc_removeEventHandler;
            };
        } forEach keys _handlers;

        GVAR(tfarEventHandlers) = createHashMap;
        GVAR(tfarHandlersActive) = false;
    };

    // Interest release is a valid stop signal: end any active transmission now
    ["interest"] call FUNC(stopTransmit);

    // No interested client left: drop the stored per-client options and push floors
    GVAR(pushMsByClient) = createHashMap;
    GVAR(options) = createHashMap;

    // The kit may have changed entirely: drop the display name cache and the
    // watchdog's kit enumeration
    GVAR(displayNames) = createHashMap;
    GVAR(radioIdsCache) = [];
};
