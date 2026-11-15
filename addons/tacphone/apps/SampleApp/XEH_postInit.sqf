#include "script_component.hpp"

// SampleApp is request/response only, so there is no post-init setup yet. When
// it grows game-driven pushes, this is where the interest CBA handlers go (see
// the root README, "Data interests"); they fire locally on the real 0 -> 1 and
// 1 -> 0 transitions, and every real app registers them idempotently here:
//
// ["ace_tacphone_interestActivated", {
//     params ["_interest"];
//     if (_interest != "SampleApp.counter") exitWith {};
//     // install exactly the event handlers the push path needs
// }] call CBA_fnc_addEventHandler;
// ["ace_tacphone_interestDeactivated", {
//     params ["_interest"];
//     if (_interest != "SampleApp.counter") exitWith {};
//     // remove exactly the handlers added on activate
// }] call CBA_fnc_addEventHandler;
//
// An app that ends up with no post-init work may drop the
// Extended_PostInit_EventHandlers class from CfgEventHandlers.hpp.
