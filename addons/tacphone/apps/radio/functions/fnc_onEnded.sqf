#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Mission "Ended" handler: force-end any active transmission, nothing may
 * outlive the mission.
 *
 * Arguments:
 * 0: Winner <SIDE or STRING> (unused)
 * 1: Side <SIDE> (unused)
 * 2: Type <NUMBER> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * addMissionEventHandler ["Ended", ace_tacphone_radio_fnc_onEnded]
 *
 * Public: No
 */

params ["_winner", "_side", "_type"];

["ended"] call FUNC(stopTransmit);
