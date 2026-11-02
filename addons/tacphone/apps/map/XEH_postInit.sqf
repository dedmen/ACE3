#include "script_component.hpp"

//#include "initKeybinds.inc.sqf"

// Marker and GPS handlers are demand driven: they only exist while a client holds the matching interest.
// See FUNC(onInterestChanged).
["ace_tacphone_interestActivated", {
    [_this select 0, true] call FUNC(onInterestChanged);
}] call CBA_fnc_addEventHandler;
["ace_tacphone_interestDeactivated", {
    [_this select 0, false] call FUNC(onInterestChanged);
}] call CBA_fnc_addEventHandler;
