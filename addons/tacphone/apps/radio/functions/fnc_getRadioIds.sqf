#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Returns the current stable ids of the local player's radios, SR first then LR.
 * SR ids are the class string, LR ids are "<netId> <qualifier>". The netId is
 * captured at enumeration time, because an LR object can become objNull later
 * and the netId cannot be read then.
 *
 * Return Value:
 * Radio ids <ARRAY of STRING> (SR first, then LR; empty when the player has none)
 *
 * Example:
 * call ace_tacphone_radio_fnc_getRadioIds
 *
 * Public: No
 */

// TFAR_fnc_LRRadiosList recurses infinitely with a null player, so guard it first
if (isNull player) exitWith { [] };

private _ids = [];

// SR radios: the class string is the stable id
_ids append (call FUNC(srRadioClasses));

// LR radios: an entry is [object, qualifier]; malformed or gone entries are
// dropped (a bare object would misroute into the LR settings path in TFAR)
{
    if ((_x isEqualType []) && {count _x >= 2} && {!isNull (_x select 0)}
        && {(_x select 1) isEqualType ""}) then {
        _ids pushBack format ["%1 %2", netId (_x select 0), _x select 1];
    };
} forEach (player call TFAR_fnc_LRRadiosList);

_ids
