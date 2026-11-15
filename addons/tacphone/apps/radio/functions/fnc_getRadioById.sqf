#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Resolves a stable radio id back to a TFAR radio handle, re-checked against the
 * player's current radiosList/LRRadiosList on every call. A stale or fabricated
 * id therefore fails instead of touching a radio the player no longer has.
 *
 * Arguments:
 * 0: Radio id <STRING> (class string for SR, "<netId> <qualifier>" for LR)
 *
 * Return Value:
 * Radio handle <STRING or ARRAY>, or nil when the radio is not in the current
 * inventory (a non-string id fails here too: it is a malformed request, and
 * the `in` check below would be a runtime error for it)
 *
 * Example:
 * ["tf_anprc152"] call ace_tacphone_radio_fnc_getRadioById
 *
 * Public: No
 */

params [["_radioId", ""]];

if (!(_radioId isEqualType "") || {isNull player}) exitWith { nil };

// SR: the id is the class string itself
private _srRadios = call FUNC(srRadioClasses);
if (_radioId in _srRadios) exitWith { _radioId };

// LR: "<netId> <qualifier>"; the qualifier is the index-1 string of the LRRadiosList entry.
// The result accumulates in _handle with an explicit final return: an `exitWith`
// nested inside a `then` block only exits that block's scope (the value is
// dropped and execution continues), which silently broke every LR lookup.
private _handle = nil;

if (" " in _radioId) then {
    private _parts = _radioId splitString " ";
    if (count _parts >= 2) then {
        private _netId = _parts select 0;
        private _qualifier = _parts select 1;

        private _lrRadios = player call TFAR_fnc_LRRadiosList;
        private _found = _lrRadios findIf {
            (_x isEqualType []) && {netId (_x select 0) == _netId} && {(_x select 1) == _qualifier}
        };

        if (_found != -1) then {
            _handle = _lrRadios select _found;
        };
    };
};

_handle
