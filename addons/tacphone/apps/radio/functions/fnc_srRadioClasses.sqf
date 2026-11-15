#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Class names of the local player's SW radios. This TFAR build hands back
 * inventory objects from TFAR_fnc_radiosList, but the TFAR SW API (and the
 * stable SR ids) want class name strings, so objects are normalized here.
 *
 * Return Value:
 * Class names <ARRAY of STRING> (empty when the player has none)
 *
 * Example:
 * call ace_tacphone_radio_fnc_srRadioClasses
 *
 * Public: No
 */

if (isNull player) exitWith { [] };

(player call TFAR_fnc_radiosList) apply {
    if (_x isEqualType "") then { _x } else { typeOf _x }
}
