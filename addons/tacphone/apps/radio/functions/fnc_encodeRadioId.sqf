#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Encodes a TFAR radio handle into its stable protocol id.
 * SR radios (the class string) map to themselves; LR radios ([object, qualifier])
 * map to "<netId> <qualifier>". An id containing a space is LR; SR class names
 * never contain one. A bare inventory object (as fired by some TFAR builds in
 * tangent events) normalizes to its class name.
 *
 * Arguments:
 * 0: Radio handle <STRING, OBJECT or ARRAY> (class string or inventory object
 *    for SR, [object, qualifier] for LR)
 *
 * Return Value:
 * Radio id <STRING>
 *
 * Example:
 * ["tf_anprc152"] call ace_tacphone_radio_fnc_encodeRadioId
 *
 * Public: No
 */

params ["_radio"];

if (_radio isEqualType []) exitWith {
    format ["%1 %2", netId (_radio select 0), _radio select 1]
};

if (_radio isEqualType objNull) exitWith { typeOf _radio };

_radio
