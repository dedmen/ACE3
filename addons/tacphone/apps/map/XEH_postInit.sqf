#include "script_component.hpp"

// Marker and GPS handlers are demand driven: they only exist while a client holds the matching interest.
// See FUNC(onInterestChanged).
// Re-init guard: if postInit runs again while the previous registration still lives,
// remove the stored ids first so the handlers never double up.
if (!isNil QGVAR(interestEhIds)) then {
    {
        _x call CBA_fnc_removeEventHandler;
    } forEach GVAR(interestEhIds);
};

GVAR(interestEhIds) = [
    ["ace_tacphone_interestActivated", ["ace_tacphone_interestActivated", {
        [_this select 0, true] call FUNC(onInterestChanged);
    }] call CBA_fnc_addEventHandler],
    ["ace_tacphone_interestDeactivated", ["ace_tacphone_interestDeactivated", {
        [_this select 0, false] call FUNC(onInterestChanged);
    }] call CBA_fnc_addEventHandler]
];
