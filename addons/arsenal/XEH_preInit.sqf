#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

[QGVAR(camInverted), "CHECKBOX", "Invert camera controls", "ACE3 Arsenal", false] call CBA_Settings_fnc_init; // TBL
[QGVAR(canUseCurrentMagTab), "CHECKBOX", "Can use currentMag tab", "ACE3 Arsenal", false] call CBA_Settings_fnc_init; // TBL
[QGVAR(enableModIcons), "CHECKBOX", "Enable mod logos", "ACE3 Arsenal", true] call CBA_Settings_fnc_init; // TBL
[QGVAR(fontHeight), "SLIDER", "Font height for left and right panels", "ACE3 Arsenal", [1, 10, 4.5, 1]] call CBA_Settings_fnc_init; // TBL

ADDON = true;
