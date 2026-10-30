#include "script_component.hpp"

if (!hasInterface) exitWith {};

//Global variable to default:
GVAR(currentShowMode) = DISPLAY_MODE_CLOSED;

//Add deviceKey entry:
private _conditionCode = {
    "ACE_Tacphone" in (ACE_player call EFUNC(common,uniqueItems))
};
private _toggleCode = {
    if !([ACE_player, objNull, ["notOnMap", "isNotInside", "isNotSitting"]] call EFUNC(common,canInteractWith)) exitWith {};
    [] call FUNC(openDisplay); //toggle display mode
};
private _closeCode = {
    if (GVAR(currentShowMode) == DISPLAY_MODE_CLOSED) exitWith {};
    [DISPLAY_MODE_CLOSED] call FUNC(openDisplay);
};
[(localize LSTRING(tacphoneDisplayName)), QPATHTOF(data\tx\icon_phone_ca.paa), _conditionCode, _toggleCode, _closeCode] call EFUNC(common,deviceKeyRegisterNew);

//Register keybinds:
#include "initKeybinds.inc.sqf"
