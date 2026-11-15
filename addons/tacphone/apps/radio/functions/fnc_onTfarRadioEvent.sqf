#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Shared handler for the TFAR radio change events:
 * TFAR_event_OnSWchannelSet, TFAR_event_OnLRchannelSet, TFAR_event_OnSWstereoSet,
 * TFAR_event_OnLRstereoSet, TFAR_event_OnFrequencyChanged,
 * TFAR_event_OnFrequencyChangedFromUI and TFAR_event_OnRadiosReceived.
 * Each event only sets the push flag: TFAR_event_OnFrequencyChanged fires per
 * 0.1 slider step while a TFAR frequency slider moves, so it must be
 * coalesced and never assemble inline.
 *
 * Arguments:
 * 0..n: The TFAR event payload (unused, the next snapshot re-reads everything)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["TFAR_event_OnFrequencyChanged", ace_tacphone_radio_fnc_onTfarRadioEvent] call CBA_fnc_addEventHandler
 *
 * Public: No
 */

// Coalesced: at most one snapshot per burst, early-out on no interest inside
call FUNC(commitRevision);
call FUNC(pushRadioState);
