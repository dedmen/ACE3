#include "script_component.hpp"

//#include "initKeybinds.inc.sqf"

// Marker event handlers are demand driven: they only exist while a client holds INTEREST_MARKERS.
// See FUNC(onInterestActivated) / FUNC(onInterestDeactivated).
["ace_tacphone_interestActivated", FUNC(onInterestActivated)] call CBA_fnc_addEventHandler;
["ace_tacphone_interestDeactivated", FUNC(onInterestDeactivated)] call CBA_fnc_addEventHandler;
